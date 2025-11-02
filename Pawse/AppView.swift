//
//  AppView.swift
//  Pawse
//
//  Main container view that manages tab navigation
//

import SwiftUI

struct AppView: View {
    @State private var selectedTab: TabItem = .community
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            TabView(selection: $selectedTab) {
                CommunityView()
                    .tag(TabItem.community)
                
                CameraView()
                    .tag(TabItem.camera)
                
                ProfileView()
                    .tag(TabItem.profile)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            
            // Bottom navigation bar
            BottomBarView(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

#Preview {
    AppView()
}
