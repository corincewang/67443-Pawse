// MARK: - Friend Photo Card
import SwiftUI
struct FriendPhotoCard: View {
    let feedItem: FriendsFeedItem
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var displayedImage: UIImage?
    @State private var isLiked: Bool
    @State private var currentVotes: Int
    
    init(feedItem: FriendsFeedItem, feedViewModel: FeedViewModel) {
        self.feedItem = feedItem
        self.feedViewModel = feedViewModel
        _isLiked = State(initialValue: feedItem.has_voted)
        _currentVotes = State(initialValue: feedItem.votes)
        // Check cache synchronously to prevent flash
        _displayedImage = State(initialValue: ImageCache.shared.image(forKey: feedItem.image_link))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Photo with like button overlay
            GeometryReader { geometry in
                let imageWidth = geometry.size.width * 0.95
                let imageHeight = imageWidth  // Square 1:1 ratio
                let imageLeftOffset = geometry.size.width * 0.025  // 2.5% left margin
                
                VStack(alignment: .leading, spacing: 12) {
                    // User info header - aligned with photo left edge
                    NavigationLink {
                        OtherUserProfileView(userId: feedItem.owner_id)
                    } label: {
                        HStack(spacing: 12) {
                            // Pet profile photo
                            if !feedItem.pet_profile_photo.isEmpty {
                                let profileImageURL = AWSManager.shared.getPhotoURL(from: feedItem.pet_profile_photo)
                                AsyncImage(url: profileImageURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 48, height: 48)
                                            .clipShape(Circle())
                                    case .failure(_), .empty:
                                        Circle()
                                            .fill(Color.pawseGolden)
                                            .frame(width: 48, height: 48)
                                            .overlay(
                                                Text(feedItem.pet_name.prefix(1).uppercased())
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(.pawseOliveGreen)
                                            )
                                    @unknown default:
                                        Circle()
                                            .fill(Color.pawseGolden)
                                            .frame(width: 48, height: 48)
                                            .overlay(
                                                Text(feedItem.pet_name.prefix(1).uppercased())
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(.pawseOliveGreen)
                                            )
                                    }
                                }
                            } else {
                                Circle()
                                    .fill(Color.pawseGolden)
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Text(feedItem.pet_name.prefix(1).uppercased())
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.pawseOliveGreen)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feedItem.pet_name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.pawseBrown)
                                
                                HStack(spacing: 4) {
                            Text("@\(feedItem.owner_nickname)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                            // Show contest tag if this is a contest photo
                            if let contestTag = feedItem.contest_tag {
                                Text("•")
                                    .foregroundColor(.gray)
                                
                                Text("#\(contestTag)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.pawseOrange)
                            }
                        }
                    }
                            
                            Spacer()
                        }
                        .padding(.leading, imageLeftOffset)
                    }
                    .buttonStyle(.plain)
                    
                    // Photo with like button overlay
                    ZStack {
                        if let image = displayedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: imageWidth, height: imageHeight)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            Rectangle()
                                .fill(Color.pawseGolden.opacity(0.3))
                                .frame(width: imageWidth, height: imageHeight)
                                .cornerRadius(12)
                                .overlay(
                                    ProgressView()
                                )
                        }
                        
                        // Like button positioned absolutely
                        HStack(spacing: 6) {
                            Button(action: {
                                // Store original state before optimistic update
                            let wasLiked = isLiked
                            
                            // Optimistically update UI
                                isLiked.toggle()
                                currentVotes += isLiked ? 1 : -1
                                
                                Task {
                                    if feedItem.is_contest_photo, let contestPhotoId = feedItem.contest_photo_id {
                                    // For contest photos, need to get contest ID and call contest vote method
                                    let contestController = ContestController()
                                    if let activeContest = try? await contestController.fetchCurrentContest(),
                                       let contestId = activeContest.id {
                                        // Create a ContestFeedItem to pass to the toggle method
                                        let contestFeedItem = ContestFeedItem(
                                            contest_photo_id: contestPhotoId, // Use the actual contest_photo_id
                                            pet_name: feedItem.pet_name,
                                            owner_nickname: feedItem.owner_nickname,
                                            owner_id: feedItem.owner_id,
                                            image_link: feedItem.image_link,
                                            votes: feedItem.votes,
                                            submitted_at: feedItem.posted_at,
                                            contest_tag: feedItem.contest_tag ?? "",
                                            has_voted: wasLiked, // Use the state BEFORE toggle
                                            score: 0,
                                            pet_profile_photo: feedItem.pet_profile_photo
                                        )
                                        await feedViewModel.toggleVoteOnContestPhoto(item: contestFeedItem, contestId: contestId)
                                    }
                                } else {
                                    // For regular photos, use the friends photo toggle
                                    await feedViewModel.toggleVoteOnFriendsPhoto(item: feedItem)
                                    }
                            }
                            }) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(isLiked ? .red : .white)
                                    .shadow(color: .black.opacity(0.3), radius: 2)
                            }
                            
                            Text("\(currentVotes)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        .position(x: imageWidth - 30, y: imageHeight - 30)
                    }
                    .frame(width: imageWidth, height: imageHeight)
                    .padding(.leading, imageLeftOffset)
                }
            }
        }
        .frame(height: UIScreen.main.bounds.width * 0.95)
        .task {
            if !feedItem.image_link.isEmpty && displayedImage == nil {
                // Only load if not already cached
                if let image = await ImageCache.shared.loadImage(forKey: feedItem.image_link) {
                    displayedImage = image
                }
            }
        }
        .onChange(of: feedViewModel.userVotedPhotoIds) { newVotedIds in
            // Sync isLiked with feedViewModel when votes change from other feeds
            let shouldBeLiked = newVotedIds.contains(feedItem.photo_id)
            if isLiked != shouldBeLiked {
                isLiked = shouldBeLiked
            }
        }
        .onChange(of: feedViewModel.friendsFeed) { updatedFeed in
            // Sync currentVotes when the feed array is updated from other feeds
            if let updatedItem = updatedFeed.first(where: { $0.photo_id == feedItem.photo_id }) {
                if currentVotes != updatedItem.votes {
                    currentVotes = updatedItem.votes
                }
            }
        }
    }
}

// MARK: - Contest Photo Card

struct ContestPhotoCard: View {
    let feedItem: ContestFeedItem
    @ObservedObject var feedViewModel: FeedViewModel
    @ObservedObject var contestViewModel: ContestViewModel
    @State private var displayedImage: UIImage?
    @State private var showShare = false
    @State private var currentVotes: Int
    @State private var isLiked: Bool
    
    init(feedItem: ContestFeedItem, feedViewModel: FeedViewModel, contestViewModel: ContestViewModel) {
        self.feedItem = feedItem
        self.feedViewModel = feedViewModel
        self.contestViewModel = contestViewModel
        _isLiked = State(initialValue: feedItem.has_voted)
        _currentVotes = State(initialValue: feedItem.votes)
        // Check cache synchronously to prevent flash
        _displayedImage = State(initialValue: ImageCache.shared.image(forKey: feedItem.image_link))
    }
    
    var body: some View {
        // Photo with vote and share buttons overlay
        GeometryReader { geometry in
            let imageWidth = geometry.size.width * 0.95
            let imageHeight = imageWidth  // Square 1:1 ratio
            let imageLeftOffset = geometry.size.width * 0.025  // 2.5% left margin
            
            VStack(alignment: .leading, spacing: 12) {
                // User info header - aligned with photo left edge
                NavigationLink {
                    OtherUserProfileView(userId: feedItem.owner_id)
                } label: {
                    HStack(spacing: 12) {
                        // Pet profile photo
                        if !feedItem.pet_profile_photo.isEmpty {
                            let profileImageURL = AWSManager.shared.getPhotoURL(from: feedItem.pet_profile_photo)
                            AsyncImage(url: profileImageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 48, height: 48)
                                        .clipShape(Circle())
                                case .failure(_), .empty:
                                    Circle()
                                        .fill(Color.pawseGolden)
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(feedItem.pet_name.prefix(1).uppercased())
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.pawseOliveGreen)
                                        )
                                @unknown default:
                                    Circle()
                                        .fill(Color.pawseGolden)
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(feedItem.pet_name.prefix(1).uppercased())
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.pawseOliveGreen)
                                        )
                                }
                            }
                        } else {
                            Circle()
                                .fill(Color.pawseGolden)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(feedItem.pet_name.prefix(1).uppercased())
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.pawseOliveGreen)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feedItem.pet_name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.pawseBrown)
                            
                            HStack(spacing: 4) {
                                Text("@\(feedItem.owner_nickname)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Text("•")
                                    .foregroundColor(.gray)
                                
                                Text("#\(feedItem.contest_tag)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.pawseOrange)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.leading, imageLeftOffset)
                }
                .buttonStyle(.plain)
                
                // Photo with vote and share buttons overlay
                ZStack {
                    if let image = displayedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: imageWidth, height: imageHeight)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.pawseGolden.opacity(0.3))
                            .frame(width: imageWidth, height: imageHeight)
                            .cornerRadius(12)
                            .overlay(
                                ProgressView()
                            )
                    }
                    
                    // Like button positioned absolutely
                    HStack(spacing: 6) {
                        Button(action: {
                            // Optimistically update UI
                            isLiked.toggle()
                            currentVotes += isLiked ? 1 : -1
                            
                            Task {
                                if let contestId = contestViewModel.activeContests.first?.id {
                                    await feedViewModel.toggleVoteOnContestPhoto(item: feedItem, contestId: contestId)
                                }
                            }
                        }) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(isLiked ? .red : .white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        
                        Text("\(currentVotes)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                    .position(x: imageWidth - 30, y: imageHeight - 30)
                }
                .frame(width: imageWidth, height: imageHeight)
                .padding(.leading, imageLeftOffset)
            }
        }
        .frame(height: UIScreen.main.bounds.width * 0.95)
        .task {
            if !feedItem.image_link.isEmpty && displayedImage == nil {
                // Only load if not already cached
                if let image = await ImageCache.shared.loadImage(forKey: feedItem.image_link) {
                    displayedImage = image
                }
            }
        }
        .onChange(of: feedViewModel.userVotedPhotoIds) { newVotedIds in
            // Sync isLiked with feedViewModel when votes change from other feeds
            let shouldBeLiked = newVotedIds.contains(feedItem.contest_photo_id)
            if isLiked != shouldBeLiked {
                isLiked = shouldBeLiked
            }
        }
        .onChange(of: feedViewModel.contestFeed) { updatedFeed in
            // Sync currentVotes when the feed array is updated from other feeds
            if let updatedItem = updatedFeed.first(where: { $0.contest_photo_id == feedItem.contest_photo_id }) {
                if currentVotes != updatedItem.votes {
                    currentVotes = updatedItem.votes
                }
            }
        }
    }
}

// MARK: - Global Photo Card (supports both regular photos and contest photos)

struct GlobalPhotoCard: View {
    let feedItem: GlobalFeedItem
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var displayedImage: UIImage?
    @State private var isLiked: Bool
    @State private var currentVotes: Int
    
    init(feedItem: GlobalFeedItem, feedViewModel: FeedViewModel) {
        self.feedItem = feedItem
        self.feedViewModel = feedViewModel
        _isLiked = State(initialValue: feedItem.has_voted)
        _currentVotes = State(initialValue: feedItem.votes)
        // Check cache synchronously to prevent flash
        _displayedImage = State(initialValue: ImageCache.shared.image(forKey: feedItem.image_link))
    }
    
    var body: some View {
        // Photo with like button overlay
        GeometryReader { geometry in
            let imageWidth = geometry.size.width * 0.95
            let imageHeight = imageWidth  // Square 1:1 ratio
            let imageLeftOffset = geometry.size.width * 0.025  // 2.5% left margin
            
            VStack(alignment: .leading, spacing: 12) {
                // User info header - aligned with photo left edge
                NavigationLink {
                    OtherUserProfileView(userId: feedItem.owner_id)
                } label: {
                    HStack(spacing: 12) {
                        // Pet profile photo
                        if !feedItem.pet_profile_photo.isEmpty {
                            let profileImageURL = AWSManager.shared.getPhotoURL(from: feedItem.pet_profile_photo)
                            AsyncImage(url: profileImageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 48, height: 48)
                                        .clipShape(Circle())
                                case .failure(_), .empty:
                                    Circle()
                                        .fill(Color.pawseGolden)
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(feedItem.pet_name.prefix(1).uppercased())
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.pawseOliveGreen)
                                        )
                                @unknown default:
                                    Circle()
                                        .fill(Color.pawseGolden)
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(feedItem.pet_name.prefix(1).uppercased())
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.pawseOliveGreen)
                                        )
                                }
                            }
                    } else {
                        Circle()
                            .fill(Color.pawseGolden)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(feedItem.pet_name.prefix(1).uppercased())
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.pawseOliveGreen)
                            )
                    }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feedItem.pet_name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.pawseBrown)
                            
                            HStack(spacing: 4) {
                                Text("@\(feedItem.owner_nickname)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                // Show friend badge if this is from a friend
                            if feedItem.is_from_friend {
                                ZStack {
                                    Circle()
                                        .fill(Color.pawseOliveGreen)
                                        .frame(width: 16, height: 16)
                                    
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Show contest tag if this is a contest photo
                                if let contestTag = feedItem.contest_tag {
                                    Text("•")
                                        .foregroundColor(.gray)
                                    
                                    Text("#\(contestTag)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.pawseOrange)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.leading, imageLeftOffset)
                }
                .buttonStyle(.plain)
                
                // Photo with like button overlay
                ZStack {
                    if let image = displayedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: imageWidth, height: imageHeight)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.pawseGolden.opacity(0.3))
                            .frame(width: imageWidth, height: imageHeight)
                            .cornerRadius(12)
                            .overlay(
                                ProgressView()
                            )
                    }
                    
                    // Like button positioned absolutely
                    HStack(spacing: 6) {
                        Button(action: {
                            handleLikeToggle()
                        }) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(isLiked ? .red : .white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        
                        Text("\(currentVotes)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                    .position(x: imageWidth - 30, y: imageHeight - 30)
                }
                .frame(width: imageWidth, height: imageHeight)
                .padding(.leading, imageLeftOffset)
            }
        }
        .frame(height: UIScreen.main.bounds.width * 0.95)
        .task {
            if !feedItem.image_link.isEmpty && displayedImage == nil {
                // Only load if not already cached
                if let image = await ImageCache.shared.loadImage(forKey: feedItem.image_link) {
                    displayedImage = image
                }
            }
        }
        .onChange(of: feedViewModel.userVotedPhotoIds) { newVotedIds in
            // Sync isLiked with feedViewModel when votes change from other feeds
            let shouldBeLiked = newVotedIds.contains(feedItem.photo_id)
            if isLiked != shouldBeLiked {
                isLiked = shouldBeLiked
            }
        }
        .onChange(of: feedViewModel.globalFeed) { updatedFeed in
            // Sync currentVotes when the feed array is updated from other feeds
            if let updatedItem = updatedFeed.first(where: { $0.photo_id == feedItem.photo_id }) {
                if currentVotes != updatedItem.votes {
                    currentVotes = updatedItem.votes
                }
            }
        }
    }
    
    private func handleLikeToggle() {
        // Store original state before optimistic update
        let wasLiked = isLiked
        
        // Optimistically update UI
        isLiked.toggle()
        currentVotes += isLiked ? 1 : -1
        
        Task {
            // Use appropriate vote method based on photo type
            if feedItem.is_contest_photo {
                // For contest photos, need to fetch contest ID
                let contestFeedItem = ContestFeedItem(
                    contest_photo_id: feedItem.photo_id,
                    pet_name: feedItem.pet_name,
                    owner_nickname: feedItem.owner_nickname,
                    owner_id: feedItem.owner_id,
                    image_link: feedItem.image_link,
                    votes: feedItem.votes,
                    submitted_at: feedItem.posted_at,
                    contest_tag: feedItem.contest_tag ?? "",
                    has_voted: wasLiked,
                    score: 0,
                    pet_profile_photo: feedItem.pet_profile_photo
                )
                let contestController = ContestController()
                if let activeContest = try? await contestController.fetchCurrentContest(),
                   let contestId = activeContest.id {
                    await feedViewModel.toggleVoteOnContestPhoto(item: contestFeedItem, contestId: contestId)
                }
            } else {
                // For regular photos, create a FriendsFeedItem
                let friendsFeedItem = FriendsFeedItem(
                    photo_id: feedItem.photo_id,
                    pet_name: feedItem.pet_name,
                    owner_nickname: feedItem.owner_nickname,
                    owner_id: feedItem.owner_id,
                    image_link: feedItem.image_link,
                    votes: feedItem.votes,
                    posted_at: feedItem.posted_at,
                    has_voted: wasLiked,
                    contest_tag: feedItem.contest_tag,
                    is_contest_photo: feedItem.is_contest_photo,
                    contest_photo_id: feedItem.is_contest_photo ? feedItem.photo_id : nil,
                    pet_profile_photo: feedItem.pet_profile_photo
                )
                await feedViewModel.toggleVoteOnFriendsPhoto(item: friendsFeedItem)
            }
        }
    }
}

