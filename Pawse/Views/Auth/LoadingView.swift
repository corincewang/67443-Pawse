//
//  LoadingView.swift
//  Pawse
//
//  Loading screen - same as Landing1View but without button (flashes quickly)
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            // Background Image - fills entire screen (same as WelcomeView)
            Image("welcomeBackground")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

#Preview {
    LoadingView()
}
