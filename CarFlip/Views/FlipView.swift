import SwiftUI

struct FlipView: View {
    @ObservedObject var carManager: CarManager
    @Binding var selectedTab: AppTab

    /// Cars shown on consecutive half-turns of the coin; the last one is the winner.
    @State private var faces: [Car?] = [nil]
    @State private var angle = 0.0
    @State private var isFlipping = false
    @State private var result: Car?
    @State private var flipCount = 0
    @State private var landCount = 0

    private let coinSize: CGFloat = 250

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 0) {
                header
                    .padding(.top, 12)

                Spacer(minLength: 16)

                if carManager.cars.count < 2 {
                    emptyState
                } else {
                    stage
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .onAppear(perform: syncWithToday)
        .onChange(of: carManager.cars) { syncWithToday() }
        .sensoryFeedback(.impact(weight: .light), trigger: flipCount)
        .sensoryFeedback(.impact(weight: .heavy), trigger: landCount)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
            Text("Which ride\ntoday?")
                .font(.badge(34))
                .lineSpacing(-4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            
            ZStack {
                landingPulse
                CoinView(angle: angle, faces: faces, size: coinSize)
            }
            .contentShape(Circle())
            .onTapGesture(perform: flip)
            .accessibilityElement()
            .accessibilityLabel(result.map { "Coin showing \($0.name)" } ?? "Coin")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { flip() }

            resultLabel
                .frame(height: 96)
                .padding(.top, 8)

            Spacer(minLength: 16)

            Button(action: flip) {
                Label(result == nil ? "Flip the coin" : "Flip again", systemImage: "arrow.trianglehead.2.clockwise")
                    .textCase(.uppercase)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isFlipping)
            .opacity(isFlipping ? 0.6 : 1)
            .animation(.easeInOut(duration: 0.2), value: isFlipping)
        }
    }

    private var resultLabel: some View {
        VStack(spacing: 6) {
            if isFlipping {
                Eyebrow("Flipping…")
                    .transition(.opacity)
            } else if let result {
                Eyebrow("Today you're driving")
                Text(result.name)
                    .font(.badge(30))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(Theme.brandGradient)
                    .id(result.id)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.6).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                Eyebrow("Tap the coin to decide")
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.6), value: result?.id)
        .animation(.easeInOut(duration: 0.2), value: isFlipping)
    }

    private var landingPulse: some View {
        Circle()
            .stroke(Theme.gold, lineWidth: 3)
            .frame(width: coinSize, height: coinSize)
            .keyframeAnimator(initialValue: Pulse(), trigger: landCount) { view, pulse in
                view
                    .scaleEffect(pulse.scale)
                    .opacity(pulse.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    LinearKeyframe(1, duration: 0.01)
                    CubicKeyframe(1.55, duration: 0.9)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0.9, duration: 0.01)
                    CubicKeyframe(0, duration: 0.9)
                }
            }
            .allowsHitTesting(false)
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            CoinView(angle: 0, faces: [nil], size: coinSize * 0.8)

            VStack(spacing: 10) {
                Text("Build your garage")
                    .font(.badge(22))
                Text("Add at least two cars and let the coin pick your daily ride.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 28)

            Spacer(minLength: 16)

            Button {
                selectedTab = .garage
            } label: {
                Label("Open garage", systemImage: "plus")
                    .textCase(.uppercase)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    // MARK: - Flipping

    private func syncWithToday() {
        guard !isFlipping else { return }
        let todaysCar = carManager.getRecordForDate(Date()).flatMap { carManager.car(withId: $0.carId) }
        result = todaysCar
        faces = [todaysCar]
        angle = 0
    }

    private func flip() {
        let cars = carManager.cars
        guard !isFlipping, cars.count >= 2, let winner = cars.randomElement() else { return }

        // Every half-turn reveals a new face; neighbours never repeat so each turn visibly changes.
        var sequence: [Car?] = [faces.last ?? nil]
        for _ in 0..<Int.random(in: 7...10) {
            sequence.append(cars.filter { $0 != sequence.last }.randomElement())
        }
        if sequence.last == winner {
            sequence.append(cars.filter { $0 != winner }.randomElement())
        }
        sequence.append(winner)

        faces = sequence
        angle = 0
        isFlipping = true
        flipCount += 1

        let halfTurns = Double(sequence.count - 1)
        withAnimation(.timingCurve(0.2, 0.7, 0.25, 1, duration: 2.6)) {
            angle = halfTurns * 180
        } completion: {
            land(on: winner)
        }
    }

    private func land(on winner: Car) {
        // Collapse to a single face so the next flip starts from an upright coin.
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            faces = [winner]
            angle = 0
        }
        carManager.recordFlip(car: winner)
        isFlipping = false
        result = winner
        landCount += 1
    }
}

private struct Pulse {
    var scale: CGFloat = 1
    var opacity: Double = 0
}

// MARK: - Coin

/// A two-sided coin tossed end over end. Which car it shows is derived from the
/// current angle, so the face swaps exactly when the coin is edge-on.
struct CoinView: View, Animatable {
    var angle: Double
    let faces: [Car?]
    let size: CGFloat

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    private var halfTurn: Int {
        let slot = Int(((angle + 90) / 180).rounded(.down))
        return min(max(slot, 0), faces.count - 1)
    }

    /// 0 → 1 → 0 over the whole toss; drives the arc and the shadow.
    private var airtime: Double {
        let total = Double(faces.count - 1) * 180
        guard total > 0 else { return 0 }
        return sin(.pi * min(max(angle / total, 0), 1))
    }

    var body: some View {
        let showsBack = !halfTurn.isMultiple(of: 2)
        let facing = abs(cos(angle * .pi / 180))

        ZStack {
            Ellipse()
                .fill(.black.opacity(0.28 - airtime * 0.18))
                .frame(width: size * (0.75 - airtime * 0.3), height: size * 0.09)
                .blur(radius: 10 + airtime * 8)
                .offset(y: size * 0.62)

            CoinFace(car: faces[halfTurn], size: size)
                // The back side is seen through the coin, so un-mirror it.
                .scaleEffect(y: showsBack ? -1 : 1)
                .brightness(-0.25 * (1 - facing))
                .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), perspective: 0.35)
                .scaleEffect(1 + airtime * 0.16)
                .offset(y: -airtime * size * 0.45)
        }
        .frame(width: size, height: size)
    }
}

struct CoinFace: View {
    let car: Car?
    let size: CGFloat

    var body: some View {
        let rim = size * 0.07

        ZStack {
            Circle()
                .fill(Theme.goldGradient)

            // Reeded inner edge
            Circle()
                .strokeBorder(
                    Theme.goldDeep.opacity(0.55),
                    style: StrokeStyle(lineWidth: rim * 0.45, dash: [1.5, 2.5])
                )
                .padding(rim * 0.3)

            Group {
                if car == nil {
                    ZStack {
                        Theme.brandGradient
                        Text("?")
                            .font(.badge(size * 0.4, weight: .black))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                    }
                } else {
                    CarArtwork(car: car)
                }
            }
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Theme.goldDeep.opacity(0.8), lineWidth: 2))
            .padding(rim)

            // Glossy highlight
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.45), .white.opacity(0)],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
        }
        .frame(width: size, height: size)
        .shadow(color: Theme.goldDeep.opacity(0.35), radius: 12, y: 6)
    }
}

#Preview {
    FlipView(carManager: CarManager(), selectedTab: .constant(.flip))
}
