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
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Wave shape background
                WaveBottomBarShape()
                    .fill(Color.bottomBarBackground)
                    .frame(height: 120)
                
                // Tab buttons positioned at wave peaks - shifted 15px left (10 + 5)
                HStack(spacing: 0) {
                    // First button center at (width/4 - 40) + 30, shifted 15px left
                    Spacer()
                        .frame(width: geometry.size.width / 4 - 35)
                    
                    TabButton(
                        tab: .profile,
                        selectedTab: $selectedTab
                    )
                    .offset(x: -15, y: 0)
                    
                    Spacer()
                        .frame(width: geometry.size.width / 4 - 30)
                    
                    TabButton(
                        tab: .camera,
                        selectedTab: $selectedTab
                    )
                    .offset(x: -15, y: 0)
                    
                    Spacer()
                        .frame(width: geometry.size.width / 4 - 30)
                    
                    TabButton(
                        tab: .community,
                        selectedTab: $selectedTab
                    )
                    .offset(x: -15, y: 0)
                    
                    Spacer()
                        .frame(width: geometry.size.width / 4 - 45)
                }
                .frame(height: 90)
            }
        }
        .frame(height: 90)
        .edgesIgnoringSafeArea(.bottom)
    }
}

// MARK: - Wave Bottom Bar Shape
struct WaveBottomBarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let waveHeight: CGFloat = 16
        
        // Calculate peak positions based on actual button centers, shifted 20px left
        // Button layout: Spacer(width/4-40) + Button(60) + Spacer(width/4-40) + Button(60) + Spacer(width/4-40) + Button(60) + Spacer(width/4-40)
        // Button center is 30px from button left edge (60/2)
        // Shift all peaks 20px to the left
        let buttonWidth: CGFloat = 60
        let spacerWidth = width / 4 - 40
        let leftShift: CGFloat = 20
        let firstPeakX = spacerWidth + buttonWidth / 2 - leftShift  // First button center shifted left
        let secondPeakX = spacerWidth + buttonWidth + spacerWidth + buttonWidth / 2 - leftShift  // Second button center shifted left
        let thirdPeakX = spacerWidth + buttonWidth + spacerWidth + buttonWidth + spacerWidth + buttonWidth / 2 - leftShift  // Third button center shifted left
        
        // Valley positions - exactly between peaks
        let firstValleyX = (firstPeakX + secondPeakX) / 2
        let secondValleyX = (secondPeakX + thirdPeakX) / 2
        
        // Start from top-left
        path.move(to: CGPoint(x: 0, y: waveHeight))
        
        let leftToPeak1 = firstPeakX
        path.addCurve(
            to: CGPoint(x: firstPeakX, y: 0),
            control1: CGPoint(x: leftToPeak1 * 0.5, y: waveHeight),
            control2: CGPoint(x: leftToPeak1 * 0.5, y: 0)
        )
        
        // First peak to first valley - smooth, gradual descent
        let peak1ToValley1 = firstValleyX - firstPeakX
        path.addCurve(
            to: CGPoint(x: firstValleyX, y: waveHeight),
            control1: CGPoint(x: firstPeakX + peak1ToValley1 * 0.3, y: 0),
            control2: CGPoint(x: firstPeakX + peak1ToValley1 * 0.7, y: waveHeight)
        )
        
        // First valley to second peak - smooth, gradual ascent
        let valley1ToPeak2 = secondPeakX - firstValleyX
        path.addCurve(
            to: CGPoint(x: secondPeakX, y: 0),
            control1: CGPoint(x: firstValleyX + valley1ToPeak2 * 0.5, y: waveHeight),
            control2: CGPoint(x: firstValleyX + valley1ToPeak2 * 0.5, y: 0)
        )
        
        // Second peak to second valley - smooth, gradual descent
        let peak2ToValley2 = secondValleyX - secondPeakX
        path.addCurve(
            to: CGPoint(x: secondValleyX, y: waveHeight),
            control1: CGPoint(x: secondPeakX + peak2ToValley2 * 0.3, y: 0),
            control2: CGPoint(x: secondPeakX + peak2ToValley2 * 0.7, y: waveHeight)
        )
        
        // Second valley to third peak - smooth, gradual ascent
        let valley2ToPeak3 = thirdPeakX - secondValleyX
        path.addCurve(
            to: CGPoint(x: thirdPeakX, y: 0),
            control1: CGPoint(x: secondValleyX + valley2ToPeak3 * 0.3, y: waveHeight),
            control2: CGPoint(x: secondValleyX + valley2ToPeak3 * 0.7, y: 0)
        )
        
        // Third peak to right edge - symmetric, vertical descent from peak
        let peak3ToRight = width - thirdPeakX
        path.addCurve(
            to: CGPoint(x: width, y: waveHeight),
            control1: CGPoint(x: thirdPeakX + peak3ToRight * 0.5, y: 0),
            control2: CGPoint(x: thirdPeakX + peak3ToRight * 0.5, y: waveHeight)
        )
        
        // Complete the shape
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
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
                        .frame(width: 50, height: 56)
                }
                
                Image(systemName: tab.iconName)
                    .font(.system(size: 20, weight: .medium))
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

