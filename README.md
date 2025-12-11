# Pawse - Pet Photo Sharing & Contest App

## Overview

**Pawse** is a comprehensive iOS social media application built with SwiftUI that allows pet owners to capture, share, and celebrate their pets' special moments. The app combines social networking features with an automated photo contest system, creating an engaging community for pet lovers.

### Core Purpose
- **Photo Sharing**: Upload and share pet photos with friends or the public
- **Social Connections**: Connect with other pet owners and view their pet photos
- **Photo Contests**: Participate in weekly rotating themed photo contests
- **Feed Algorithm**: Custom-built feed ranking system that prioritizes engagement and recency
- **Profile Management**: Create and manage multiple pet profiles

---

## Key Features

### 1. **Authentication & Onboarding**
- Email/password authentication via Firebase Auth
- Seamless onboarding flow for new users
- Profile setup with nickname and pet creation
- Interactive tutorial system for first-time users

### 2. **Pet Profile Management**
- Create multiple pet profiles per user
- Store pet details: name, age, gender, type, profile photo
- Photo gallery for each pet
- Guardian system (co-ownership functionality)

### 3. **Photo Upload & Storage**
- Camera integration for capturing pet photos
- AWS S3 bucket storage for images
- Privacy controls: public, friends-only, or private
- Image caching for performance optimization

### 4. **Social Features**
- Friend connection system (send/accept/reject requests)
- Real-time notifications for friend requests and contest activity
- View friends' pet photos in dedicated feed
- Search and add friends by nickname

### 5. **Contest System**
- **Automatic Weekly Rotation**: 50+ pre-generated themed contests
- **Smart Ranking Algorithm**: Custom feed algorithm combines votes, recency, and randomness
- **Leaderboard**: Top 10 contest entries displayed
- **Contest Themes**: Categories include cute, funny, active, seasonal, and more

### 6. **Feed System**
Three distinct feed types with custom algorithms:

#### **Friends Feed**
- Shows photos from mutual friends and user's own photos
- Sorted by recency (newest first)
- Includes both regular photos and contest entries
- Displays contest tags for entered photos

#### **Global Feed**
- Public photos from all users
- Highlights friends' photos
- Mixed feed of contest entries and regular posts
- Sorted by timestamp

#### **Contest Feed**
- **Custom Ranking Algorithm**: `score = (votes × 3) + recency_boost + random_factor`
  - Vote weight: ×3 multiplier
  - Recency boost: Newer entries get higher scores (decays over time)
  - Randomness: 0-5 points for fairness
- User's own entries appear first
- Other entries ranked by algorithm score

### 7. **Voting System**
- Vote on photos in feeds and contests
- Vote tracking persisted per user in UserDefaults
- Real-time vote count updates
- Prevents duplicate voting

---

## Architecture

### Tech Stack
- **Frontend**: SwiftUI (iOS)
- **Backend**: Firebase (Auth, Firestore, Functions)
- **Storage**: AWS S3
- **State Management**: Combine framework with MVVM pattern

### Project Structure

```
Pawse/
├── Config/              # Configuration files
│   ├── FirebaseManager.swift    # Firebase singleton
│   ├── AWSManager.swift         # AWS S3 operations
│   └── AWSConfig.swift          # S3 bucket configuration
│
├── Models/              # Data models
│   ├── User.swift               # User profile
│   ├── Pet.swift                # Pet profile
│   ├── Photo.swift              # Photo metadata
│   ├── Contest.swift            # Contest data
│   ├── ContestPhoto.swift       # Contest entry
│   ├── Connection.swift         # Friend connections
│   ├── Guardian.swift           # Co-ownership
│   ├── Notification.swift       # In-app notifications
│   └── APIResponseModels.swift  # Feed response models
│
├── Controllers/         # Business logic layer
│   ├── AuthController.swift           # Authentication
│   ├── UserController.swift           # User operations
│   ├── PetController.swift            # Pet CRUD
│   ├── PhotoController.swift          # Photo upload/fetch
│   ├── ContestController.swift        # Contest management
│   ├── FeedController.swift           # Feed coordination
│   ├── ConnectionController.swift     # Friend system
│   ├── NotificationController.swift   # Notifications
│   └── GuardianController.swift       # Co-ownership
│
├── ViewModels/          # View state management
│   ├── UserViewModel.swift        # User state
│   ├── PetViewModel.swift         # Pet state
│   ├── PhotoViewModel.swift       # Photo state
│   ├── FeedViewModel.swift        # Feed state & voting
│   ├── ContestViewModel.swift     # Contest state
│   ├── ConnectionViewModel.swift  # Friends state
│   └── GuardianViewModel.swift    # Guardian state
│
├── Services/            # Internal services
│   ├── FeedService.swift              # ⭐ Custom feed algorithm
│   ├── ContestRotationService.swift   # Auto-rotation timer
│   └── ContestThemeGenerator.swift    # Theme pool
│
├── Views/               # UI components
│   ├── RootView.swift             # Auth state router
│   ├── AppView.swift              # Main tab container
│   ├── BottomBarView.swift        # Tab navigation
│   ├── Auth/                      # Login/register screens
│   ├── Onboarding/                # Welcome flow
│   ├── Profile/                   # User & pet profiles
│   ├── Pets/                      # Pet management
│   ├── Photos/                    # Photo gallery
│   ├── Community/                 # Friends & social
│   ├── Contests/                  # Contest views
│   ├── Components/                # Reusable UI
│   └── CameraView.swift           # Camera interface
│
├── Utilities/           # Helper utilities
│   ├── ImageCache.swift           # In-memory image cache
│   ├── ImageLoader.swift          # Async image loading
│   └── Extensions/                # Swift extensions
│
└── Constants.swift      # App-wide constants
```

---

## Important Files & Functionalities

### 🔥 Critical Backend Files

#### **`FeedService.swift`** ⭐ MOST IMPORTANT
**Location**: `Pawse/Services/FeedService.swift`

This is the **internal custom API** for feed generation and ranking. Contains three main algorithms:

1. **`generateFriendsFeed()`** (Lines 19-143)
   - Fetches mutual friends via connection matching
   - Retrieves photos from friends (public and friends-only)
   - Checks if photos are in contests
   - Sorts by recency (most recent first)

2. **`generateGlobalFeed()`** (Lines 147-297)
   - Gets all public photos and contest entries
   - Marks photos from friends
   - Sorts by timestamp

3. **`generateContestFeed()`** (Lines 301-423)
   - **Custom Ranking Algorithm** (Lines 425-449):
     ```swift
     score = (votes × 3) + recency_boost + randomness
     - Vote weight: ×3 multiplier
     - Recency boost: max(0, 10 - (hours_since_submission × 0.1))
     - Randomness: random value 0-5
     ```
   - User's entries always appear first
   - Others ranked by calculated score

**Why It Matters**: This file replaces an external API and implements the core engagement logic that makes feeds feel dynamic and fair.

---

#### **`ContestRotationService.swift`**
**Location**: `Pawse/Services/ContestRotationService.swift`

Automated background service that:
- Runs hourly timer to check for expired contests
- Automatically deactivates old contests
- Creates new contests using random themes
- Ensures at least one active contest exists

---

#### **`ContestThemeGenerator.swift`**
**Location**: `Pawse/Services/ContestThemeGenerator.swift`

Contains **50+ pre-generated contest themes** including:
- Cute themes: "Cutest Sleeping Position", "Puppy Dog Eyes"
- Funny themes: "Funniest Derp Face", "Silliest Sitting Position"
- Active themes: "Best Action Shot", "Fastest Zoomies"
- Seasonal themes: Winter, Spring, Summer, Fall
- Special themes: "Best Costume", "Fluffiest Fur"

**Extensible**: Can be enhanced with AI (OpenAI) integration for dynamic theme generation.

---

#### **`AWSManager.swift`**
**Location**: `Pawse/Config/AWSManager.swift`

Handles all S3 operations:
- **`uploadToS3Simple()`**: Upload photos to S3
- **`downloadImage()`**: Download with caching
- **`deleteFromS3()`**: Remove photos from bucket
- **`deletePetFolderFromS3()`**: Cascade delete pet folders

**Configuration**: `AWSConfig.swift` contains bucket name and region.

---

#### **`FirebaseManager.swift`**
**Location**: `Pawse/Config/FirebaseManager.swift`

Singleton providing access to:
- `auth`: Firebase Authentication
- `db`: Firestore database
- `functions`: Cloud Functions

---

### 📊 Data Models

#### **`Photo.swift`**
Standard photo with:
- `image_link`: S3 key
- `pet`: Pet reference
- `privacy`: "public" | "friends_only" | "private"
- `votes_from_friends`: Vote count for non-contest photos

#### **`ContestPhoto.swift`**
Contest entry with:
- `contest`: Contest reference
- `photo`: Photo reference
- `votes`: Contest-specific vote count
- `submitted_at`: Entry timestamp

**Important**: Photos can exist in **both** `photos` and `contest_photos` collections. Contest votes are tracked separately.

---

### 🎮 Controllers

#### **`FeedController.swift`** 
**Location**: `Pawse/Controllers/FeedController.swift`

Coordinates feed requests:
- Routes to internal `FeedService` for custom algorithm
- `fetchLeaderboardResponse()`: Top 10 contest entries
- `fetchFriendsFeedItems()`: Friends feed
- `fetchGlobalFeedItems()`: Global feed
- `fetchContestFeedItems()`: Contest feed with ranking

#### **`ContestController.swift`**
**Location**: `Pawse/Controllers/ContestController.swift`

Contest management:
- `joinContest()`: Create contest_photo entry
- `fetchCurrentContest()`: Get active contest
- `createContestFromRandomTheme()`: Auto-create new contest
- `rotateExpiredContests()`: Check and rotate
- `ensureActiveContest()`: Guarantee one active contest

#### **`ConnectionController.swift`**
**Location**: `Pawse/Controllers/ConnectionController.swift`

Friend system:
- `sendFriendRequest()`: Create pending connection
- `approveRequest()`: Accept friend request
- `removeFriend()`: Delete connection
- `fetchConnections()`: Get all connections (bidirectional)

---

### 🖼️ ViewModels

#### **`FeedViewModel.swift`**
**Location**: `Pawse/ViewModels/FeedViewModel.swift`

Manages feed state:
- `friendsFeed`, `globalFeed`, `contestFeed`: Feed arrays
- `userVotedPhotoIds`: Persisted vote tracking (UserDefaults)
- `votePhoto()`: Update votes locally and in Firestore
- `loadAllFeeds()`: Refresh all feeds

**Persistence**: Votes are saved per-user in UserDefaults to prevent duplicate voting across app sessions.

#### **`ContestViewModel.swift`**
**Location**: `Pawse/ViewModels/ContestViewModel.swift`

Contest state management:
- `activeContests`: Current active contests
- `currentContest`: The single active contest
- `contestFeed`: Ranked contest entries
- `fetchCurrentContest()`: Lazy loads contest if needed

---

### 🎨 Key Views

#### **`RootView.swift`**
**Location**: `Pawse/Views/RootView.swift`

Root navigation:
- Checks Firebase auth state
- Routes to `WelcomeView` (unauthenticated) or `AppView` (authenticated)
- Ensures user has completed profile setup (nickname exists)

#### **`AppView.swift`**
**Location**: `Pawse/AppView.swift`

Main tab container:
- Four tabs: Profile, Camera, Contest, Community
- Manages bottom navigation bar
- Initializes contest rotation service on launch
- Handles tutorial system

#### **`ContestView.swift`**
**Location**: `Pawse/Views/Contests/ContestView.swift`

Contest tab:
- Displays active contest banner with theme
- Shows leaderboard (top 10)
- Contest feed with ranked entries
- Vote functionality

#### **`ProfilePageView.swift`**
**Location**: `Pawse/Views/Profile/ProfilePageView.swift`

User profile:
- Displays user's pets
- Pet selection for viewing galleries
- Tutorial system for new users
- Navigation to pet detail views

---

## Firebase Firestore Schema

### Collections

**`users`**
```
{
  email: String
  nick_name: String
  pets: [String]  // ["pets/{id}", ...]
  preferred_setting: [String]
  has_seen_profile_tutorial: Bool
}
```

**`pets`**
```
{
  age: Int
  gender: String  // "F" or "M"
  name: String
  owner: String  // "users/{uid}"
  profile_photo: String  // S3 key
  type: String
}
```

**`photos`**
```
{
  image_link: String  // S3 key
  pet: String  // "pets/{id}"
  privacy: String  // "public"|"friends_only"|"private"
  uploaded_at: Date
  uploaded_by: String  // "users/{uid}"
  votes_from_friends: Int
}
```

**`contests`**
```
{
  active_status: Bool
  start_date: Date
  end_date: Date
  prompt: String
}
```

**`contest_photos`** ⭐ **Requires Composite Index**
```
{
  contest: String  // "contests/{id}"
  photo: String  // "photos/{id}"
  submitted_at: Date
  votes: Int
}
```

**Required Index**: See `FIRESTORE_SETUP.md` for details.
- Fields: `contest` (Ascending), `votes` (Descending)
- Needed for leaderboard query

**`connections`**
```
{
  connection_date: Date
  status: String  // "pending"|"approved"|"rejected"
  uid1: String  // Sender UID
  user1: String  // "users/{uid}"
  uid2: String  // Recipient UID
  user2: String  // "users/{uid}"
}
```

**`notifications`**
```
{
  type: String  // "friend_request"|"friend_accepted"|"contest_vote"
  recipient_uid: String
  sender_uid: String
  sender_name: String
  message: String
  action_data: String?
  created_at: Date
  is_read: Bool
}
```

**`coowners`** (Guardians)
```
{
  date_added: Date
  guardian: String  // "users/{uid}"
  owner: String  // "users/{uid}"
  pet: String  // "pets/{id}"
  status: String  // "pending"|"approved"|"rejected"
}
```

---

## AWS S3 Structure

**Bucket Name**: `pawse-bucket`  
**Region**: `us-east-1`

### Folder Structure
```
pets/
  {petId}/
    profile/
      profile_photo.jpg
    photos/
      {photoId}.jpg
      {photoId}.jpg
      ...
```

### Operations
- **Upload**: `AWSManager.uploadToS3Simple()`
- **Download**: `AWSManager.downloadImage()` (with caching)
- **Delete**: `AWSManager.deleteFromS3()`

---

## Internal API: Feed Ranking Algorithm

### Why Custom Algorithm?

The app uses an **internal Swift-based feed service** (`FeedService.swift`) instead of an external REST API. This provides:
- **Performance**: No network latency for feed generation
- **Consistency**: Direct Firestore queries ensure data freshness
- **Control**: Custom ranking logic tailored to app needs
- **Cost**: Eliminates need for separate backend server

### Contest Ranking Formula

**Location**: `FeedService.swift` (Lines 425-449)

```swift
func calculateContestScore(votes: Int, submittedAt: Date, now: Date) -> Double {
    // 1. Vote Score: Each vote worth 3 points
    let voteScore = Double(votes) * 3.0
    
    // 2. Recency Boost: Newer entries get higher score
    let hoursSinceSubmission = now.timeIntervalSince(submittedAt) / 3600.0
    let recencyBoost = max(0, 10.0 - (hoursSinceSubmission * 0.1))
    
    // 3. Randomness Factor: 0-5 points for fairness
    let randomFactor = Double.random(in: 0...5)
    
    // 4. Total Score
    return voteScore + recencyBoost + randomFactor
}
```

### Algorithm Explanation

**Vote Weight (×3)**
- Primary ranking factor
- Encourages engagement
- Each vote contributes 3 points to total score

**Recency Boost (0-10 points)**
- Starts at 10 points for just-submitted photos
- Decays by 0.1 per hour
- Reaches 0 after 100 hours
- Ensures new entries aren't buried by older popular ones

**Randomness (0-5 points)**
- Adds unpredictability to prevent stagnation
- Gives lower-voted entries occasional visibility
- Creates dynamic feed experience

**User Priority**
- User's own contest entries always appear first (before sorting)
- Other entries sorted by calculated score

---

## Setup Instructions

### Prerequisites
1. **Xcode 15+** with iOS 17+ SDK
2. **Firebase Project** with:
   - Authentication enabled (Email/Password)
   - Firestore database
   - Required composite index (see `FIRESTORE_SETUP.md`)
3. **AWS S3 Bucket** with public read access
4. **CocoaPods** for Firebase SDK

### Installation

1. **Clone Repository**
   ```bash
   cd 67443-Pawse
   ```

2. **Install Dependencies**
   ```bash
   pod install
   ```

3. **Configure Firebase**
   - Download `GoogleService-Info.plist` from Firebase Console
   - Add to `Pawse/` directory in Xcode

4. **Configure AWS S3**
   - Edit `Pawse/Config/AWSConfig.swift`
   - Update `bucketName` and `region`

5. **Create Firestore Index**
   ```bash
   firebase deploy --only firestore:indexes
   ```
   Or follow instructions in `FIRESTORE_SETUP.md`

6. **Build & Run**
   - Open `Pawse.xcworkspace`
   - Select target device
   - Run (⌘R)

---

## Key Workflows

### User Journey

1. **Onboarding**
   - Land on welcome screen
   - Sign up with email/password
   - Set nickname
   - Create first pet profile
   - Interactive tutorial

2. **Daily Usage**
   - View friends' photos in Community tab
   - Check active contest theme
   - Upload photo via Camera tab
   - Submit photo to contest (if applicable)
   - Vote on friends' and global photos
   - Check leaderboard standings

3. **Social Interaction**
   - Search for friends by nickname
   - Send friend requests
   - Approve/reject incoming requests
   - View friends' pet profiles
   - Receive notifications for activity

### Contest Lifecycle

1. **Creation** (Automated)
   - `ContestRotationService` checks hourly
   - Deactivates expired contests
   - `ContestThemeGenerator` selects random theme
   - New contest created with 7-day duration

2. **Participation**
   - User uploads photo
   - Option to submit to active contest
   - Entry created in `contest_photos`
   - Photo appears in Contest Feed

3. **Voting**
   - Users vote on contest entries
   - Votes tracked per user in UserDefaults
   - Real-time updates to leaderboard
   - Feed ranking recalculates on refresh

4. **Completion**
   - Contest expires after 7 days
   - Final leaderboard snapshot
   - New contest auto-generates

---

## Testing Considerations

### Important Notes for Graders

1. **Firestore Index Required**
   - The app **will not function** without the composite index on `contest_photos`
   - See `FIRESTORE_SETUP.md` for setup instructions
   - Error message will provide direct link to create index

2. **AWS S3 Configuration**
   - Bucket must allow public read access
   - Update `AWSConfig.swift` with your credentials
   - Photos will not display without proper S3 setup

3. **Contest System**
   - Contests auto-rotate every 7 days
   - For testing, use `ContestAdminView` to force rotation
   - Initial contest is created on first app launch

4. **Voting Persistence**
   - Votes are stored in UserDefaults per user
   - Uninstalling app will reset vote history
   - Normal app usage persists votes across sessions

5. **Tutorial System**
   - First-time users see interactive tutorial
   - Tutorial state stored in AppStorage
   - Can be reset by deleting app

### Test Scenarios

**Create Account & Onboarding**
- Register new user
- Set nickname
- Create pet profile
- Complete tutorial

**Upload & Share**
- Take photo with camera
- Upload to S3
- Set privacy level
- View in profile gallery

**Social Features**
- Search for users
- Send friend request
- Approve friend request
- View friend's photos in feed

**Contest Participation**
- Check active contest theme
- Upload contest entry
- Vote on other entries
- View leaderboard

**Feed Algorithm**
- Verify friends feed shows only friends' photos
- Check global feed includes all public photos
- Confirm contest feed ranking (votes matter)
- Validate vote persistence

---

## Technologies & Frameworks

### iOS/Swift
- **SwiftUI**: Declarative UI framework
- **Combine**: Reactive state management
- **Foundation**: Core Swift APIs

### Backend & Services
- **Firebase Auth**: User authentication
- **Firestore**: NoSQL database
- **Firebase Functions**: Cloud Functions (optional)
- **AWS S3**: Object storage for images

### Architecture Patterns
- **MVVM**: Model-View-ViewModel
- **Repository Pattern**: Controllers as data layer
- **Service Layer**: Internal business logic
- **Singleton Pattern**: Shared managers

### Libraries
- **FirebaseSDK**: Complete Firebase suite
- **Kingfisher-like ImageLoader**: Custom async image loading

---

## Known Limitations

1. **Single Active Contest**
   - System designed for one active contest at a time
   - Multiple contests possible but not recommended

2. **S3 Delete Permissions**
   - Some S3 buckets may not allow DELETE via direct requests
   - Consider using Firebase Functions for secure deletion

3. **Offline Support**
   - App requires internet connection
   - No offline caching of Firestore data
   - Images cached after first download

4. **Scalability**
   - Feed generation happens on-device
   - Large datasets (1000+ photos) may slow feed loading
   - Consider pagination for production use

---

## Future Enhancements (Mentioned in Code)

1. **AI-Generated Contest Themes**
   - OpenAI integration in `ContestThemeGenerator.swift`
   - Dynamic theme generation based on trends

2. **Push Notifications**
   - FCM integration for real-time alerts
   - Notification for votes, friend requests, contest results

3. **Advanced Feed Filtering**
   - Filter by pet type
   - Date range selection
   - Most popular this week

4. **Video Support**
   - Extend Photo model for videos
   - Video player in feeds

5. **In-App Messaging**
   - Direct messages between friends
   - Contest entry comments

---

## Documentation Files

- **`README.md`** (this file): Comprehensive app overview
- **`CONTEST_SYSTEM.md`**: Detailed contest rotation system
- **`FIRESTORE_SETUP.md`**: Firestore index setup guide
- **`PawseTests/TEST_SETUP.md`**: Unit testing documentation

---

## Contact & Support

For questions or issues with the codebase, refer to:
- Firebase Console: https://console.firebase.google.com
- AWS S3 Console: https://console.aws.amazon.com/s3
- Firestore indexes: Check error logs for auto-generated links

---

## Summary for Graders

**Pawse** is a full-featured social media app for pet owners with:

✅ **Custom Feed Algorithm**: Internal ranking system in `FeedService.swift`  
✅ **Automated Contest System**: 50+ themes with weekly rotation  
✅ **Complete Social Features**: Friends, voting, notifications  
✅ **AWS S3 Integration**: Scalable image storage  
✅ **Firebase Backend**: Auth + Firestore database  
✅ **MVVM Architecture**: Clean separation of concerns  
✅ **Extensive Testing**: Unit tests for all major components  

**Most Important File**: `FeedService.swift` - Contains the custom ranking algorithm that powers all three feed types.

**Key Innovation**: Internal API approach eliminates external backend while providing sophisticated feed ranking that balances engagement, recency, and fairness.
