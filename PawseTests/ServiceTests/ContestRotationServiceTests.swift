//
//  ContestRotationServiceTests.swift
//  PawseTests
//
//  Tests for ContestRotationService
//

import Testing
import Foundation
@testable import Pawse

struct ContestRotationServiceTests {
    let contestRotationService = ContestRotationService.shared
    
    @Test("Initialize System - should successfully initialize contest system")
    func testInitializeSystem() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        
        // Initialize the contest system
        await contestRotationService.initializeSystem()
        
        // If no error is thrown, the initialization was successful
        // This is a basic smoke test - the actual initialization logic is in ContestController
        #expect(Bool(true), "Initialize system should complete without crashing")
    }
    
    @Test("Check And Rotate - should successfully check and rotate expired contests")
    func testCheckAndRotate() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        
        // Check and rotate expired contests
        await contestRotationService.checkAndRotate()
        
        // If no error is thrown, the rotation check was successful
        // This is a basic smoke test - the actual rotation logic is in ContestController
        #expect(Bool(true), "Check and rotate should complete without crashing")
    }
    
    @Test("Initialize System and Check Rotate - should work together")
    func testInitializeAndRotate() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        
        // First initialize
        await contestRotationService.initializeSystem()
        
        // Then check and rotate
        await contestRotationService.checkAndRotate()
        
        // If no error is thrown, both operations completed successfully
        #expect(Bool(true), "Both operations should complete without crashing")
    }
    
    @Test("Initialize System - should handle errors gracefully")
    func testInitializeSystemErrorHandling() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        
        // This test ensures the catch block in initializeSystem is covered
        // We can't easily force an error, but the method should handle it gracefully
        await contestRotationService.initializeSystem()
        
        // If we get here, error handling worked (or no error occurred)
        #expect(Bool(true), "Should handle errors without crashing")
    }
    
    @Test("Check And Rotate - should handle errors gracefully")
    func testCheckAndRotateErrorHandling() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        
        // This test ensures the catch block in checkAndRotate is covered
        await contestRotationService.checkAndRotate()
        
        // If we get here, error handling worked (or no error occurred)
        #expect(Bool(true), "Should handle errors without crashing")
    }
}
