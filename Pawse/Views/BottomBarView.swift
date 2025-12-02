//
//  BottomBarView.swift
//  Pawse
//
//  Bottom navigation bar component
//

import SwiftUI

struct BottomBarView: View {
    @Binding var selectedTab: TabItem
        var highlightedTab: TabItem? = nil
    var isTutorialActive: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                WaveBottomBarShape(tabCount: TabItem.orderedTabs.count)
                    .fill(Color.bottomBarBackground)
                    .frame(height: 110)

                HStack(alignment: .center, spacing: 0) {
                    ForEach(TabItem.orderedTabs, id: \.self) { tab in
                        TabButton(tab: tab, selectedTab: $selectedTab, isHighlighted: highlightedTab == tab, isDisabledHighlight: highlightedTab != nil && tab == .profile && (highlightedTab == .camera || highlightedTab == .contest || highlightedTab == .community), isTutorialActive: isTutorialActive, highlightedTab: highlightedTab)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 90)
                .padding(.horizontal, 8)
            }
        }
        .frame(height: 90)
        .edgesIgnoringSafeArea(.bottom)
    }
}

// MARK: - Wave Bottom Bar Shape
struct WaveBottomBarShape: Shape {
    let tabCount: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let waveHeight: CGFloat = 12

        guard tabCount > 0 else {
            path.move(to: CGPoint(x: 0, y: waveHeight))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: width, y: waveHeight))
            path.closeSubpath()
            return path
        }

        let spacing = width / CGFloat(tabCount)
        let centers = (0..<tabCount).map { spacing * (CGFloat($0) + 0.5) }
        var valleys: [CGFloat] = []
        if centers.count > 1 {
            for index in 0..<(centers.count - 1) {
                let midpoint = (centers[index] + centers[index + 1]) / 2
                valleys.append(midpoint)
            }
        }

        path.move(to: CGPoint(x: 0, y: waveHeight))

        // From start to first peak
        let firstPeakX = centers.first ?? width / 2
        path.addCurve(
            to: CGPoint(x: firstPeakX, y: 0),
            control1: CGPoint(x: firstPeakX * 0.45, y: waveHeight),
            control2: CGPoint(x: firstPeakX * 0.65, y: 0)
        )

        for index in 0..<centers.count {
            let currentPeak = centers[index]

            if index < valleys.count {
                let valleyX = valleys[index]
                path.addCurve(
                    to: CGPoint(x: valleyX, y: waveHeight),
                    control1: CGPoint(x: currentPeak + (valleyX - currentPeak) * 0.4, y: 0),
                    control2: CGPoint(x: currentPeak + (valleyX - currentPeak) * 0.6, y: waveHeight)
                )

                let nextPeak = centers[index + 1]
                path.addCurve(
                    to: CGPoint(x: nextPeak, y: 0),
                    control1: CGPoint(x: valleyX + (nextPeak - valleyX) * 0.4, y: waveHeight),
                    control2: CGPoint(x: valleyX + (nextPeak - valleyX) * 0.6, y: 0)
                )
            }
        }

        // Final segment to right edge
        let lastPeak = centers.last ?? width
        path.addCurve(
            to: CGPoint(x: width, y: waveHeight),
            control1: CGPoint(x: lastPeak + (width - lastPeak) * 0.4, y: 0),
            control2: CGPoint(x: lastPeak + (width - lastPeak) * 0.6, y: waveHeight)
        )

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
    var isHighlighted: Bool = false
    var isDisabledHighlight: Bool = false
    var isTutorialActive: Bool = false
    var highlightedTab: TabItem? = nil
    
    var isSelected: Bool {
        selectedTab == tab
    }
    
    var isDisabled: Bool {
        // During tutorial, disable all tabs except the highlighted one and the current profile tab
        if isTutorialActive {
            return tab != .profile && tab != highlightedTab
        }
        return false
    }
    
    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            selectedTab = tab
        }) {
            ZStack {
                Circle()
                    .fill((isSelected && !isDisabledHighlight) || isHighlighted ? Color.pawseOrange : Color.bottomBarBackground)
                    .frame(width: 48, height: 48)
                Image(systemName: tab.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor((isSelected && !isDisabledHighlight) || isHighlighted ? Color.white : Color.pawseBrown)
            }
            .shadow(radius: isSelected && !isDisabledHighlight ? 6 : 0)
            .opacity(isDisabled ? 0.4 : 1.0)
        }
    }
}

// MARK: - Preview
#Preview {
    BottomBarView(selectedTab: .constant(.community))
}

