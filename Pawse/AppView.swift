//
//  AppView.swift
//  Pawse
//
//  Main container view that manages tab navigation
//

import SwiftUI

struct AppView: View {
    @State private var selectedTab: TabItem = .profile
    
    var body: some View {
        ZStack {
            // Main content area
            Group {
                switch selectedTab {
                case .profile:
                    NavigationStack {
                        ProfilePageView()
                    }
                case .camera:
                    NavigationStack {
                        CameraView()
                    }
                case .community:
                    NavigationStack {
                        ContestParticipantsView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom navigation bar overlay
            VStack {
                Spacer()
                BottomBarView(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }
    }
}

#Preview {
    AppView()
}
