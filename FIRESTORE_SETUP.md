# Firestore Setup Guide

## Composite Indexes

The app requires a composite index on the `contest_photos` collection for the leaderboard query.

### Option 1: Deploy via Firebase CLI

1. Install Firebase CLI if you haven't:
```bash
npm install -g firebase-tools
```

2. Login to Firebase:
```bash
firebase login
```

3. Initialize Firebase in the project (if not already done):
```bash
firebase init firestore
```

4. Deploy the indexes:
```bash
firebase deploy --only firestore:indexes
```

### Option 2: Create Index via Console

1. Open the Firebase Console: https://console.firebase.google.com
2. Select your project
3. Go to Firestore Database → Indexes
4. Click "Create Index"
5. Configure:
   - **Collection ID**: `contest_photos`
   - **Fields to index**:
     - Field: `contest`, Order: Ascending
     - Field: `votes`, Order: Descending
   - **Query scope**: Collection

6. Click "Create"

### Option 3: Use Auto-Generated Link

When you run the app and the query fails, Firebase will show an error message with a direct link to create the index. You can:

1. Look for the error in Xcode console
2. Copy the URL from the error message (starts with `https://console.firebase.google.com/...`)
3. Open that URL in your browser
4. Click "Create Index"

The index typically takes 1-2 minutes to build.

## Why This Index is Needed

The leaderboard query in `FeedController.fetchLeaderboardResponse()` performs:
```swift
db.collection(Collection.contestPhotos)
    .whereField("contest", isEqualTo: contestRef)
    .order(by: "votes", descending: true)
    .limit(to: 10)
```

This query filters by `contest` and sorts by `votes`, which requires a composite index in Firestore.
