//
//  BottomBarView.swift
//  Pawse
//
//  Bottom navigation bar component
//

import SwiftUI

struct BottomBarView: View {
    @Binding var selectedTab: TabItem
    
    var body: some View {
        HStack(spacing: 0) {
            // Profile Tab
            TabButton(
                tab: .profile,
                selectedTab: $selectedTab
            )
            
            Spacer()
            
            // Camera Tab
            TabButton(
                tab: .camera,
                selectedTab: $selectedTab
            )
            
            Spacer()
            // Community Tab
            TabButton(
                tab: .community,
                selectedTab: $selectedTab
            )
            
        }
        .padding(.horizontal, 60)
        .padding(.top, 20)
        .padding(.bottom, 25)
        .background(
            CurvedBottomBarShape()
                .fill(Color.bottomBarBackground)
        )
    }
}

// MARK: - Curved Bottom Bar Shape
struct CurvedBottomBarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let peakHeight: CGFloat = 18  // Height of each peak
        let valleyDepth: CGFloat = 12  // Depth of valleys between peaks
        
        // Start from top-left
        path.move(to: CGPoint(x: 0, y: valleyDepth))
        
        // First peak (left side) - more semi-circular
        path.addCurve(
            to: CGPoint(x: width * 0.33, y: valleyDepth),
            control1: CGPoint(x: width * 0.08, y: valleyDepth - peakHeight),
            control2: CGPoint(x: width * 0.25, y: valleyDepth - peakHeight)
        )
        
        // Valley between first and second peak
        path.addCurve(
            to: CGPoint(x: width * 0.42, y: valleyDepth * 0.7),
            control1: CGPoint(x: width * 0.36, y: valleyDepth),
            control2: CGPoint(x: width * 0.39, y: valleyDepth * 0.85)
        )
        
        // Second peak (center) - highest and most prominent
        path.addCurve(
            to: CGPoint(x: width * 0.58, y: valleyDepth * 0.7),
            control1: CGPoint(x: width * 0.47, y: valleyDepth * 0.2),
            control2: CGPoint(x: width * 0.53, y: valleyDepth * 0.2)
        )
        
        // Valley between second and third peak
        path.addCurve(
            to: CGPoint(x: width * 0.67, y: valleyDepth),
            control1: CGPoint(x: width * 0.61, y: valleyDepth * 0.85),
            control2: CGPoint(x: width * 0.64, y: valleyDepth)
        )
        
        // Third peak (right side) - mirror of first peak
        path.addCurve(
            to: CGPoint(x: width, y: valleyDepth),
            control1: CGPoint(x: width * 0.75, y: valleyDepth - peakHeight),
            control2: CGPoint(x: width * 0.92, y: valleyDepth - peakHeight)
        )
        
        // Right side down
        path.addLine(to: CGPoint(x: width, y: height - 60))
        
        // Bottom right rounded corner
        path.addQuadCurve(
            to: CGPoint(x: width - 60, y: height),
            control: CGPoint(x: width, y: height)
        )
        
        // Bottom line
        path.addLine(to: CGPoint(x: 60, y: height))
        
        // Bottom left rounded corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: height - 60),
            control: CGPoint(x: 0, y: height)
        )
        
        // Close the path
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Tab Button Component
struct TabButton: View {
    let tab: TabItem
    @Binding var selectedTab: TabItem
    
    var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        Button(action: {
            selectedTab = tab
        }) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.pawseOrange)
                        .frame(width: 56, height: 56)
                }
                
                Image(systemName: tab.iconName)
                    .font(.system(size: 25, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color.pawseBrown)  // Muted brown for unselected
            }
            .frame(width: 60, height: 60)
        }
    }
}

// MARK: - Preview
#Preview {
    BottomBarView(selectedTab: .constant(.community))
}

