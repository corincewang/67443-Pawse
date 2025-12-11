import SwiftUI

enum TutorialStep: Int, CaseIterable {
    case welcome
    case addPet
    case uploadPhoto
    case addPhoto
    case camera
    case contest
    case community
    case finished
}

enum TutorialTarget: Hashable {
    case addPetCard
    case firstPetCard
    case contestBanner
    case headerSubtitle
    case petCardsArea
    case addPhotoButton
}

struct TutorialFramePreferenceKey: PreferenceKey {
    static var defaultValue: [TutorialTarget: CGRect] = [:]
    static func reduce(value: inout [TutorialTarget: CGRect], nextValue: () -> [TutorialTarget: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct TutorialFrameModifier: ViewModifier {
    let target: TutorialTarget
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Color.clear.preference(key: TutorialFramePreferenceKey.self, value: [target: proxy.frame(in: .global)])
            }
        )
    }
}

extension View {
    func captureTutorialFrame(_ target: TutorialTarget) -> some View {
        modifier(TutorialFrameModifier(target: target))
    }
}

struct TutorialHelpPopup: View {
    @Binding var isPresented: Bool
    let restartAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }

            VStack(spacing: 20) {
                Text("Need Help?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.pawseOliveGreen)

                Text("Relaunch the guided tour to learn where everything lives on Pawse.")
                    .font(.system(size: 18, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.pawseBrown)
                    .padding(.horizontal, 24)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                    restartAction()
                } label: {
                    Text("Start Tutorial")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.pawseOrange)
                        .cornerRadius(28)
                }
                .padding(.horizontal, 16)

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                } label: {
                    Text("Maybe Later")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.pawseBrown)
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.15), radius: 20)
        }
    }
}

enum TutorialHighlightShape {
    case rounded(cornerRadius: CGFloat)
    case circle
}

struct TutorialHighlight: Identifiable {
    let id = UUID()
    let frame: CGRect
    let padding: CGFloat
    let shape: TutorialHighlightShape
    var expandedFrame: CGRect {
        frame.insetBy(dx: -padding, dy: -padding)
    }
}

struct TutorialInteractionLayer: UIViewRepresentable {
    let allowsOverlayTap: Bool
    let passthroughRects: [CGRect]
    let onTap: () -> Void

    func makeUIView(context: Context) -> TutorialInteractionUIView {
        let view = TutorialInteractionUIView()
        view.onTap = onTap
        view.globalPassThroughRects = passthroughRects
        return view
    }

    func updateUIView(_ uiView: TutorialInteractionUIView, context: Context) {
        uiView.allowsOverlayTap = allowsOverlayTap
        uiView.globalPassThroughRects = passthroughRects
        uiView.onTap = onTap
    }
}

final class TutorialInteractionUIView: UIView {
    var allowsOverlayTap: Bool = false
    var globalPassThroughRects: [CGRect] = []
    var onTap: (() -> Void)?

    private var localPassThroughRects: [CGRect] {
        guard let window = window else { return [] }
        return globalPassThroughRects.map { globalRect in
            let localRect = convert(globalRect, from: window)
            return localRect
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let passThroughRects = localPassThroughRects
        for rect in passThroughRects where rect.contains(location) {
            return
        }
        if allowsOverlayTap {
            onTap?()
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let passThroughRects = localPassThroughRects
        for rect in passThroughRects where rect.contains(point) {
            return false
        }
        return super.point(inside: point, with: event)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let passThroughRects = localPassThroughRects
        for rect in passThroughRects where rect.contains(point) {
            return nil
        }
        return super.hitTest(point, with: event)
    }
}

struct TutorialOverlayView: View {
    let step: TutorialStep
    let highlights: [TutorialHighlight]
    let message: String
    let detail: String?
    let hintText: String
    let allowsOverlayTap: Bool
    let passthroughRects: [CGRect]
    let messageTopAnchor: CGFloat?
    let hintYPosition: CGFloat?
    let onTap: () -> Void
    let onExit: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let overlayFrame = proxy.frame(in: .global)
            let messageTop = localPosition(
                forGlobalY: messageTopAnchor,
                within: overlayFrame,
                fallback: proxy.size.height * 0.42,
                maxHeight: max(proxy.size.height - 160, 0)
            )
            let hintY = localPosition(
                forGlobalY: hintYPosition,
                within: overlayFrame,
                fallback: proxy.size.height * 0.65,
                maxHeight: max(proxy.size.height - 60, 0)
            )
            ZStack(alignment: .topTrailing) {
                spotlightLayer

                GeometryReader { _ in
                    TutorialInteractionLayer(
                        allowsOverlayTap: allowsOverlayTap,
                        passthroughRects: passthroughRects,
                        onTap: onTap
                    )
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: messageTop)
                    messageCard
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .allowsHitTesting(false)
                if !hintText.isEmpty {
                    hintLabel
                        .position(x: proxy.size.width / 2, y: hintY)
                        .allowsHitTesting(false)
                }

                Button(action: onExit) {
                    Circle()
                        .fill(Color.pawseWarmGrey)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .padding(.trailing, 28)
                .padding(.top, 60)
            }
            .ignoresSafeArea()
        }
    }

    private var messageCard: some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.pawseBrown)
                .multilineTextAlignment(.center)
            if let detail = detail {
                Text(detail)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.pawseOliveGreen)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 12)
        .padding(.horizontal, 24)
    }

    private var hintLabel: some View {
        Text(hintText)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.25))
            .cornerRadius(16)
    }

    private var spotlightLayer: some View {
        Color.black.opacity(0.65)
            .overlay(
                ZStack {
                    ForEach(highlights) { highlight in
                        highlightShape(for: highlight)
                            .blendMode(.destinationOut)
                    }
                }
            )
            .compositingGroup()
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func highlightShape(for highlight: TutorialHighlight) -> some View {
        let expanded = highlight.frame.insetBy(dx: -highlight.padding, dy: -highlight.padding)
        switch highlight.shape {
        case .rounded(let radius):
            RoundedRectangle(cornerRadius: radius)
                .frame(width: max(expanded.width, 0.1), height: max(expanded.height, 0.1))
                .position(x: expanded.midX, y: expanded.midY)
        case .circle:
            let diameter = max(max(expanded.width, expanded.height), 0.1)
            Circle()
                .frame(width: diameter, height: diameter)
                .position(x: expanded.midX, y: expanded.midY)
        }
    }

    private func localPosition(forGlobalY globalY: CGFloat?, within overlayFrame: CGRect, fallback: CGFloat, maxHeight: CGFloat) -> CGFloat {
        let localValue: CGFloat
        if let globalY {
            localValue = globalY - overlayFrame.minY
        } else {
            localValue = fallback
        }
        let upperBound = max(maxHeight, 0)
        return min(max(localValue, 0), upperBound)
    }
}
