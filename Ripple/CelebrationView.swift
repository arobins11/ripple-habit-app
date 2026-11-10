
import SwiftUI

struct CelebrationView: View {
    let message: String

    @State private var isAnimating = false

    private let particleCount = 70

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 16) {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 55))
                        .foregroundStyle(.orange)

                    Text(message)
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)

                    Text("Keep up the great work!")
                        .foregroundStyle(.secondary)

                    Button("Celebrate Again 🎉") {
                        celebrate()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(30)

                // Native SwiftUI confetti animation
                ForEach(0..<particleCount, id: \.self) { index in
                    confettiPiece(
                        index: index,
                        size: geometry.size
                    )
                }
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                celebrate()
            }
        }
    }

    private func confettiPiece(
        index: Int,
        size: CGSize
    ) -> some View {
        let colors: [Color] = [
            .red, .blue, .green, .orange,
            .purple, .pink, .yellow
        ]

        let x = sin(Double(index) * 2.4) * size.width * 0.48
        let y = size.height * 0.85 + CGFloat(index % 8) * 12

        return RoundedRectangle(cornerRadius: 2)
            .fill(colors[index % colors.count])
            .frame(
                width: index % 2 == 0 ? 9 : 6,
                height: index % 2 == 0 ? 13 : 9
            )
            .rotationEffect(.degrees(isAnimating ? Double(index * 47) : 0))
            .offset(
                x: isAnimating ? x : 0,
                y: isAnimating ? y : -size.height * 0.45
            )
            .opacity(isAnimating ? 0 : 1)
            .animation(
                .easeOut(duration: 2.2)
                    .delay(Double(index % 12) * 0.025),
                value: isAnimating
            )
    }

    private func celebrate() {
        isAnimating = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isAnimating = true
        }
    }
}

