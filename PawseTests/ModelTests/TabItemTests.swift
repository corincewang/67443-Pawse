import XCTest
@testable import Pawse

class TabItemTests: XCTestCase {
    func testTabItemRawValues() {
        XCTAssertEqual(TabItem.profile.rawValue, "profile")
        XCTAssertEqual(TabItem.camera.rawValue, "camera")
        XCTAssertEqual(TabItem.community.rawValue, "community")
        XCTAssertEqual(TabItem.contest.rawValue, "contest")
    }
    
    func testTabItemId() {
        XCTAssertEqual(TabItem.profile.id, "profile")
        XCTAssertEqual(TabItem.camera.id, "camera")
        XCTAssertEqual(TabItem.community.id, "community")
        XCTAssertEqual(TabItem.contest.id, "contest")
    }
    
    func testTabItemTitles() {
        XCTAssertEqual(TabItem.profile.title, "Profile")
        XCTAssertEqual(TabItem.camera.title, "Camera")
        XCTAssertEqual(TabItem.community.title, "Community")
        XCTAssertEqual(TabItem.contest.title, "Contest")
    }
    
    func testTabItemIconNames() {
        XCTAssertEqual(TabItem.profile.iconName, "person.fill")
        XCTAssertEqual(TabItem.camera.iconName, "camera.fill")
        XCTAssertEqual(TabItem.community.iconName, "person.3.fill")
        XCTAssertEqual(TabItem.contest.iconName, "trophy.fill")
    }
    
    func testTabItemCaseIterable() {
        let allCases = TabItem.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.profile))
        XCTAssertTrue(allCases.contains(.camera))
        XCTAssertTrue(allCases.contains(.community))
        XCTAssertTrue(allCases.contains(.contest))
    }
    
    func testTabItemOrderedTabs() {
        let orderedTabs = TabItem.orderedTabs
        XCTAssertEqual(orderedTabs.count, 4)
        XCTAssertEqual(orderedTabs[0], .profile)
        XCTAssertEqual(orderedTabs[1], .camera)
        XCTAssertEqual(orderedTabs[2], .contest)
        XCTAssertEqual(orderedTabs[3], .community)
    }
    
    func testTabItemIdentifiable() {
        // Test that TabItem conforms to Identifiable
        let profileId: String = TabItem.profile.id
        let cameraId: String = TabItem.camera.id
        
        XCTAssertEqual(profileId, "profile")
        XCTAssertEqual(cameraId, "camera")
    }
    
    func testTabItemFromRawValue() {
        XCTAssertEqual(TabItem(rawValue: "profile"), .profile)
        XCTAssertEqual(TabItem(rawValue: "camera"), .camera)
        XCTAssertEqual(TabItem(rawValue: "community"), .community)
        XCTAssertEqual(TabItem(rawValue: "contest"), .contest)
        XCTAssertNil(TabItem(rawValue: "invalid"))
    }
}
