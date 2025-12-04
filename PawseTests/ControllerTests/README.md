# Controller Tests Documentation

This directory contains comprehensive test suites for all controllers in the Pawse application.

## Test Files Overview

### 1. AuthControllerTests.swift
Tests for authentication operations including:
- User registration with valid/invalid email
- Password strength validation
- User login (success and error cases)
- Sign out functionality
- Password reset
- Current user ID retrieval

**Key Test Cases:**
- ✅ Register with valid credentials
- ✅ Register with invalid email (error handling)
- ✅ Register with weak password (error handling)
- ✅ Login existing user
- ✅ Login with wrong password (error handling)
- ✅ Login non-existent user (error handling)
- ✅ Sign out functionality
- ✅ Get current UID

### 2. UserControllerTests.swift
Tests for user profile operations including:
- Fetching user by ID
- Updating user profile (nickname, preferences)
- Marking tutorial as completed
- Searching users by email

**Key Test Cases:**
- ✅ Fetch user by ID
- ✅ Fetch non-existent user (error handling)
- ✅ Update user profile
- ✅ Mark tutorial completed
- ✅ Search user by email
- ✅ Search with non-existent email
- ✅ Update with empty nickname

### 3. ConnectionControllerTests.swift
Tests for friendship/connection operations including:
- Sending friend requests
- Fetching connections
- Approving friend requests
- Removing friends

**Key Test Cases:**
- ✅ Send friend request
- ✅ Fetch all connections for user
- ✅ Approve friend request
- ✅ Remove friend connection
- ✅ Fetch connections for user with no connections

### 4. GuardianControllerTests.swift
Tests for pet co-owner (guardian) operations including:
- Requesting guardian access
- Fetching guardians for a pet
- Approving/rejecting guardian requests
- Fetching pending invitations
- Fetching pets where user is guardian

**Key Test Cases:**
- ✅ Request guardian access
- ✅ Fetch guardians for pet
- ✅ Approve guardian request
- ✅ Reject guardian request
- ✅ Fetch pending invitations
- ✅ Fetch pets for guardian
- ✅ Fetch guardians for pet with no guardians

### 5. NotificationControllerTests.swift
Tests for notification system including:
- Creating notifications
- Fetching notifications
- Marking notifications as read
- Deleting notifications

**Key Test Cases:**
- ✅ Create notification
- ✅ Create notification with action data
- ✅ Fetch notifications for user
- ✅ Verify notification ordering (by created_at)
- ✅ Mark notification as read
- ✅ Delete notification
- ✅ Fetch notifications for user with no notifications

### 6. ContestControllerTests.swift
Tests for contest management including:
- Creating contests
- Fetching active contests
- Joining contests
- Managing contest lifecycle
- Fetching leaderboards

**Key Test Cases:**
- ✅ Create contest
- ✅ Fetch active contests
- ✅ Fetch current contest
- ✅ Join contest (create contest photo entry)
- ✅ Fetch leaderboard (sorted by votes)
- ✅ Create contest from random theme
- ✅ Ensure active contest (maintain exactly one)
- ✅ Rotate expired contests

### 7. FeedControllerTests.swift
Tests for feed generation including:
- Fetching leaderboard response
- Fetching friends feed
- Fetching contest feed
- Fetching global feed
- Vote filtering

**Key Test Cases:**
- ✅ Fetch leaderboard response with contest info
- ✅ Handle no active contest gracefully
- ✅ Fetch friends feed items
- ✅ Fetch contest feed items
- ✅ Fetch global feed items
- ✅ Exclude voted photos from feeds

## Test Configuration

### Test User ID
Most tests use a test user ID: `xtYAlZO1IQOvhiUEuI2CHcgZANz1`

### Test Data Management
- Tests create unique test data using UUID prefixes
- Tests include cleanup logic to remove test data after execution
- Some tests wait for Firestore indexing (500ms delays)

### Running Tests
Run all controller tests:
```bash
xcodebuild test -scheme Pawse -destination 'platform=iOS Simulator,name=iPhone 15'
```

Run specific test file:
```bash
xcodebuild test -scheme Pawse -only-testing:PawseTests/AuthControllerTests
```

## Best Practices Used

1. **Unique Test Data**: Each test creates unique data using UUID to avoid conflicts
2. **Cleanup**: Tests clean up after themselves by deleting created data
3. **Async/Await**: All tests properly use async/await for Firebase operations
4. **Error Handling**: Tests verify both success and error cases
5. **Descriptive Names**: Test function names clearly describe what they test
6. **Assertions**: Uses Swift Testing `#expect` for clear assertions
7. **Firestore Delays**: Includes appropriate delays for Firestore indexing

## Dependencies

- Firebase Auth
- Firebase Firestore
- Swift Testing framework

## Notes

- Some tests may fail if Firebase is not properly configured
- Tests require network connectivity to Firebase
- Some tests depend on test user data existing in Firestore
- Tests use the development Firebase environment
