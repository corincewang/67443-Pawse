//
//  FeedService.swift
//  Pawse
//
//  Created on 11/9/25.
//

import Foundation
import FirebaseFirestore

/// Internal service for generating ranked feeds
class FeedService {
    static let shared = FeedService()
    private init() {}
    
    // MARK: - Friends Feed Generation
    
    /// Generates friends feed with most recent photos from mutual friends
    /// - Parameters:
    ///   - userId: Current user's ID
    ///   - userVotedPhotoIds: Set of photo IDs the user has voted on
    /// - Returns: Array of FriendsFeedItem sorted by recency
    func generateFriendsFeed(for userId: String, userVotedPhotoIds: Set<String>) async throws -> [FriendsFeedItem] {
        let db = FirebaseManager.shared.db
        
        // 1. Get mutual friends (approved status)
        // Simplified: Just get ALL approved connections and find where current user is involved
        
        let allConnectionsSnap = try await db.collection(Collection.connections)
            .whereField("status", isEqualTo: "approved")
            .getDocuments()
        
        var friendUserIds = Set<String>()
        
        for doc in allConnectionsSnap.documents {
            if let connection = try? doc.data(as: Connection.self) {
                // Check if current user is involved in this connection
                let uid2Match = connection.uid2 == userId
                let uid1Match = connection.uid1 == userId
                
                if uid1Match {
                    // Current user is sender, friend is recipient
                    friendUserIds.insert(connection.uid2)
                } else if uid2Match {
                    // Current user is recipient
                    if let uid1 = connection.uid1 {
                        // New format: friend is sender
                        friendUserIds.insert(uid1)
                    } else {
                        // Old format: need to manually add - tell user to delete and re-add
                        print("⚠️ Old connection found - please delete and re-add friend")
                    }
                }
            }
        }
        
        print("ℹ️ Found \(friendUserIds.count) friends for user \(userId)")
        
        guard !friendUserIds.isEmpty else {
            print("ℹ️ No mutual friends found")
            return []
        }
        
        // 2. Get all photos from friends (publicPhoto and friendsOnly)
        var feedItems: [FriendsFeedItem] = []
        
        for friendId in friendUserIds {
            let friendRef = "users/\(friendId)"
            
            // Fetch pets owned by this friend
            let petsSnap = try await db.collection(Collection.pets)
                .whereField("owner", isEqualTo: friendRef)
                .getDocuments()
            
            for petDoc in petsSnap.documents {
                guard let pet = try? petDoc.data(as: Pet.self),
                      let petId = pet.id else { continue }
                
                let petRef = "pets/\(petId)"
                
                // Fetch photos for this pet (public or friends-only)
                let photosSnap = try await db.collection(Collection.photos)
                    .whereField("pet", isEqualTo: petRef)
                    .getDocuments()
                
                for photoDoc in photosSnap.documents {
                    guard let photo = try? photoDoc.data(as: Photo.self),
                          let photoId = photo.id,
                          photo.privacy == "public" || photo.privacy == "friends_only" else { continue }
                    
                    // Fetch owner info
                    guard let ownerSnap = try? await db.collection(Collection.users).document(friendId).getDocument(),
                          let owner = try? ownerSnap.data(as: User.self) else { continue }
                    
                    let feedItem = FriendsFeedItem(
                        photo_id: photoId,
                        pet_name: pet.name,
                        owner_nickname: owner.nick_name,
                        owner_id: friendId,
                        image_link: photo.image_link,
                        votes: photo.votes_from_friends,
                        posted_at: photo.uploaded_at.ISO8601Format(),
                        has_voted: userVotedPhotoIds.contains(photoId)
                    )
                    
                    feedItems.append(feedItem)
                }
            }
        }
        
        // 3. Sort by most recent first (using ISO8601 string comparison)
        feedItems.sort { $0.posted_at > $1.posted_at }
        
        print("✅ Generated friends feed: \(feedItems.count) items")
        return feedItems
    }

    // MARK: - Global Feed Generation

    func generateGlobalFeed(for userId: String, userVotedPhotoIds: Set<String>) async throws -> [FriendsFeedItem] {
        let db = FirebaseManager.shared.db

        let photosSnap = try await db.collection(Collection.photos)
            .whereField("privacy", isEqualTo: "public")
            .order(by: "uploaded_at", descending: true)
            .limit(to: 100)
            .getDocuments()

        var feedItems: [FriendsFeedItem] = []

        for photoDoc in photosSnap.documents {
            guard let photo = try? photoDoc.data(as: Photo.self),
                  let photoId = photo.id else { continue }

            let petId = photo.pet.replacingOccurrences(of: "pets/", with: "")

            guard let petSnap = try? await db.collection(Collection.pets).document(petId).getDocument(),
                  let pet = try? petSnap.data(as: Pet.self) else { continue }

            let ownerId = pet.owner.replacingOccurrences(of: "users/", with: "")
            guard let ownerSnap = try? await db.collection(Collection.users).document(ownerId).getDocument(),
                  let owner = try? ownerSnap.data(as: User.self) else { continue }

            let feedItem = FriendsFeedItem(
                photo_id: photoId,
                pet_name: pet.name,
                owner_nickname: owner.nick_name,
                owner_id: ownerId,
                image_link: photo.image_link,
                votes: photo.votes_from_friends,
                posted_at: photo.uploaded_at.ISO8601Format(),
                has_voted: userVotedPhotoIds.contains(photoId)
            )

            feedItems.append(feedItem)
        }

        print("✅ Generated global feed: \(feedItems.count) items")
        return feedItems
    }
    
    // MARK: - Contest Feed Generation
    
    /// Generates contest feed with ranked entries using voting algorithm
    /// - Parameters:
    ///   - userId: Current user's ID
    ///   - contestId: Active contest ID
    ///   - userVotedPhotoIds: Set of photo IDs the user has voted on
    /// - Returns: Array of ContestFeedItem sorted by score (user's own entries first)
    func generateContestFeed(for userId: String, contestId: String, userVotedPhotoIds: Set<String>) async throws -> [ContestFeedItem] {
        let db = FirebaseManager.shared.db
        let contestRef = "contests/\(contestId)"
        
        print("🔍 Generating contest feed for contest: \(contestId)")
        
        // 1. Fetch all contest photos for this contest
        let contestPhotosSnap = try await db.collection(Collection.contestPhotos)
            .whereField("contest", isEqualTo: contestRef)
            .getDocuments()
        
        print("🔍 Found \(contestPhotosSnap.documents.count) contest photos")
        
        var userEntries: [ContestFeedItem] = []
        var otherEntries: [(item: ContestFeedItem, score: Double)] = []
        
        let now = Date()
        
        for doc in contestPhotosSnap.documents {
            do {
                let contestPhoto = try doc.data(as: ContestPhoto.self)
                guard let contestPhotoId = contestPhoto.id else {
                    print("⚠️ ContestPhoto missing ID, skipping")
                    continue
                }
                
                print("✅ Decoded ContestPhoto: \(contestPhotoId)")
                
                // Extract photo ID
                let photoId = contestPhoto.photo.replacingOccurrences(of: "photos/", with: "")
                print("🔍 Fetching photo: \(photoId)")
                
                // Fetch photo
                guard let photoSnap = try? await db.collection(Collection.photos).document(photoId).getDocument() else {
                    print("❌ Photo document not found: \(photoId)")
                    continue
                }
                
                guard let photo = try? photoSnap.data(as: Photo.self) else {
                    print("❌ Failed to decode Photo: \(photoId)")
                    print("   Raw data: \(photoSnap.data() ?? [:])")
                    continue
                }
                print("✅ Decoded Photo: \(photoId)")
                
                // Extract pet ID
                let petId = photo.pet.replacingOccurrences(of: "pets/", with: "")
                print("🔍 Fetching pet: \(petId)")
                
                // Fetch pet
                guard let petSnap = try? await db.collection(Collection.pets).document(petId).getDocument() else {
                    print("❌ Pet document not found: \(petId)")
                    continue
                }
                
                guard let pet = try? petSnap.data(as: Pet.self) else {
                    print("❌ Failed to decode Pet: \(petId)")
                    print("   Raw data: \(petSnap.data() ?? [:])")
                    continue
                }
                print("✅ Decoded Pet: \(pet.name)")
                
                // Extract owner ID
                let ownerId = pet.owner.replacingOccurrences(of: "users/", with: "")
                print("🔍 Fetching owner: \(ownerId)")
                
                // Fetch owner
                guard let ownerSnap = try? await db.collection(Collection.users).document(ownerId).getDocument() else {
                    print("❌ User document not found: \(ownerId)")
                    continue
                }
                
                guard let owner = try? ownerSnap.data(as: User.self) else {
                    print("❌ Failed to decode User: \(ownerId)")
                    print("   Raw data: \(ownerSnap.data() ?? [:])")
                    continue
                }
                print("✅ Decoded User: \(owner.nick_name)")
                
                // Get contest tag
                print("🔍 Fetching contest: \(contestId)")
                guard let contestSnap = try? await db.collection(Collection.contests).document(contestId).getDocument() else {
                    print("❌ Contest document not found: \(contestId)")
                    continue
                }
                
                guard let contest = try? contestSnap.data(as: Contest.self) else {
                    print("❌ Failed to decode Contest: \(contestId)")
                    print("   Raw data: \(contestSnap.data() ?? [:])")
                    continue
                }
                print("✅ Decoded Contest: \(contest.prompt)")
                
                let feedItem = ContestFeedItem(
                    contest_photo_id: contestPhotoId,
                    pet_name: pet.name,
                    owner_nickname: owner.nick_name,
                    owner_id: ownerId,
                    image_link: photo.image_link,
                    votes: contestPhoto.votes,
                    submitted_at: contestPhoto.submitted_at.ISO8601Format(),
                    contest_tag: contest.prompt,
                    has_voted: userVotedPhotoIds.contains(contestPhotoId),
                    score: 0 // Will be calculated below
                )
                
                print("✅ Created ContestFeedItem for pet: \(pet.name)")
                
                // Separate user's own entries
                if ownerId == userId {
                    userEntries.append(feedItem)
                    print("   → Added to user entries")
                } else {
                    // Calculate ranking score for others
                    let score = calculateContestScore(
                        votes: contestPhoto.votes,
                        submittedAt: contestPhoto.submitted_at,
                        now: now
                    )
                    otherEntries.append((feedItem, score))
                    print("   → Added to other entries with score: \(score)")
                }
            } catch {
                print("❌ Error processing contest photo doc \(doc.documentID): \(error.localizedDescription)")
                continue
            }
        }
        
        // 2. Sort other entries by score
        otherEntries.sort { $0.score > $1.score }
        
        // 3. Combine: user's entries first, then ranked others
        var finalFeed = userEntries
        finalFeed.append(contentsOf: otherEntries.map { var item = $0.item; item.score = $0.score; return item })
        
        print("✅ Generated contest feed: \(finalFeed.count) items (\(userEntries.count) user entries)")
        return finalFeed
    }
    
    // MARK: - Ranking Algorithm
    
    /// Calculate contest entry score based on votes, recency, and randomness
    /// Algorithm from Pawse API: votes×3 + recency_boost + randomness
    private func calculateContestScore(votes: Int, submittedAt: Date, now: Date) -> Double {
        // Vote weight: ×3
        let voteScore = Double(votes) * 3.0
        
        // Recency boost: newer entries get higher score
        let hoursSinceSubmission = now.timeIntervalSince(submittedAt) / 3600.0
        let recencyBoost = max(0, 10.0 - (hoursSinceSubmission * 0.1)) // Decays over time
        
        // Randomness factor: 0-5 points for fairness
        let randomFactor = Double.random(in: 0...5)
        
        let totalScore = voteScore + recencyBoost + randomFactor
        return totalScore
    }
}
