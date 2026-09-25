import SwiftUI

enum Theme {
    static let blue = Color(red: 0.18, green: 0.45, blue: 0.98)
    static let violet = Color(red: 0.45, green: 0.20, blue: 0.90)
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.32)
    static let goldDeep = Color(red: 0.78, green: 0.53, blue: 0.14)

    static let brandGradient = LinearGradient(
        colors: [blue, violet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = AngularGradient(
        colors: [gold, goldDeep, gold, Color(red: 1, green: 0.92, blue: 0.62), goldDeep, gold],
        center: .center
    )
}

extension Font {
    /// Wide, heavy type that reads like a badge on a car's tailgate.
    static func badge(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight).width(.expanded)
    }
}

/// Small uppercase label with generous tracking, used above headlines.
struct Eyebrow: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold).width(.expanded))
            .tracking(1.6)
            .foregroundStyle(.secondary)
    }
}

/// Slowly drifting mesh gradient that gives every screen the same ambient backdrop.
struct AmbientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let drift = Float(sin(t / 4)) * 0.12
            let drift2 = Float(cos(t / 5)) * 0.12
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5 + drift, 0.45 + drift2], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1],
                ],
                colors: colors
            )
        }
        .ignoresSafeArea()
    }

    private var colors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.05, green: 0.06, blue: 0.14), Color(red: 0.09, green: 0.08, blue: 0.22), Color(red: 0.05, green: 0.05, blue: 0.12),
                Color(red: 0.08, green: 0.14, blue: 0.36), Color(red: 0.20, green: 0.12, blue: 0.42), Color(red: 0.07, green: 0.07, blue: 0.20),
                Color(red: 0.04, green: 0.04, blue: 0.10), Color(red: 0.08, green: 0.06, blue: 0.18), Color(red: 0.03, green: 0.03, blue: 0.08),
            ]
        }
        return [
            Color(red: 0.93, green: 0.95, blue: 1.00), Color(red: 0.95, green: 0.93, blue: 1.00), Color(red: 0.97, green: 0.97, blue: 1.00),
            Color(red: 0.80, green: 0.87, blue: 1.00), Color(red: 0.88, green: 0.82, blue: 1.00), Color(red: 0.94, green: 0.94, blue: 1.00),
            Color(red: 0.97, green: 0.97, blue: 0.99), Color(red: 0.94, green: 0.93, blue: 0.99), Color(red: 0.99, green: 0.99, blue: 1.00),
        ]
    }
}

/// Car photo, or a branded placeholder when the car has no photo.
struct CarArtwork: View {
    let car: Car?
    var symbolScale: CGFloat = 0.42

    var body: some View {
        GeometryReader { proxy in
            if let image = car?.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            } else {
                ZStack {
                    Theme.brandGradient
                    Image(systemName: "car.side.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(proxy.size.width, proxy.size.height) * symbolScale * 1.4)
                        .foregroundStyle(.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                }
            }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.badge(17, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Theme.brandGradient, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: Theme.violet.opacity(0.45), radius: 18, y: 10)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
