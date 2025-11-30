//
//  TabItem.swift
//  Pawse
//
//  Tab item model for bottom navigation bar
//

import Foundation

/// Represents a tab in the bottom navigation bar
enum TabItem: String, CaseIterable, Identifiable {
    case profile
    case camera
    case community
    case contest
    
    var id: String { self.rawValue }
    
    /// Display name for the tab
    var title: String {
        switch self {
        case .profile:
            return "Profile"
        case .camera:
            return "Camera"
        case .community:
            return "Community"
        case .contest:
            return "Contest"
        }
    }
    
    /// SF Symbol name for the tab icon
    var iconName: String {
        switch self {
        case .profile:
            return "person.fill"
        case .camera:
            return "camera.fill"
        case .community:
            return "person.3.fill"
        case .contest:
            return "trophy.fill"
        }
    }

    static var orderedTabs: [TabItem] {
        return [.profile, .camera, .contest, .community]
    }
}

