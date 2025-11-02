//
//  TabItem.swift
//  Pawse
//
//  Tab item model for bottom navigation bar
//

import Foundation

/// Represents a tab in the bottom navigation bar
enum TabItem: String, CaseIterable, Identifiable {
    case community
    case camera
    case profile
    
    var id: String { self.rawValue }
    
    /// Display name for the tab
    var title: String {
        switch self {
        case .community:
            return "Community"
        case .camera:
            return "Camera"
        case .profile:
            return "Profile"
        }
    }
    
    /// SF Symbol name for the tab icon
    var iconName: String {
        switch self {
        case .community:
            return "person.3.fill"
        case .camera:
            return "camera.fill"
        case .profile:
            return "person.fill"
        }
    }
}

