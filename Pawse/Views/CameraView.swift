//
//  CameraView.swift
//  Pawse
//
//  Camera page - take and share pet photos
//

import SwiftUI

struct CameraView: View {
    var body: some View {
        ZStack {
            Color(hex: "FAF7EB")
                .ignoresSafeArea()
            
            VStack {
                Text("Camera")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "F7B455"))
            }
        }
    }
}

#Preview {
    CameraView()
}

