//
//  View_SwipeBack.swift
//  Pawse
//
//  Extension to add swipe back gesture to views
//

import SwiftUI

extension View {
    func swipeBack(dismiss: DismissAction) -> some View {
        self.gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onEnded { value in
                    // Check if swipe starts from left edge (within 20 points from left)
                    // and swipes right (width > 50) with minimal vertical movement
                    let startX = value.startLocation.x
                    let translationX = value.translation.width
                    let translationY = value.translation.height
                    
                    if startX < 50 && translationX > 50 && abs(translationY) < 100 {
                        dismiss()
                    }
                }
        )
    }
}

