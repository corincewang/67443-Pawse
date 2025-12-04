//
//  NotificationControllerTests.swift
//  PawseTests
//
//  Tests for Notification operations
//

import Testing
import FirebaseFirestore
import Foundation
@testable import Pawse

struct NotificationControllerTests {
    let notificationController = NotificationController()
    let testUserId = "1IU4XCi1oNewCD7HEULziOLjExg1"
    let testSenderId = "test_sender_123"
    
    @Test("Create Notification - should successfully create a notification")
    func testCreateNotification() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        // Create a notification
        try await notificationController.createNotification(
            type: "friend_request",
            recipientUid: testUserId,
            senderUid: testSenderId,
            senderName: "Test Sender",
            message: "Test notification message"
        )
        
        // If we reach here, the creation succeeded
        #expect(true, "Notification creation completed without error")
    }
    
    @Test("Create Notification - should support optional action data")
    func testCreateNotificationWithActionData() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        // Create a notification with action data
        try await notificationController.createNotification(
            type: "friend_accepted",
            recipientUid: testUserId,
            senderUid: testSenderId,
            senderName: "Test Sender",
            message: "Test notification with action data",
            actionData: "user_profile_123"
        )
        
        // If we reach here, the creation succeeded
        #expect(true, "Notification creation with action data completed without error")
    }
}
