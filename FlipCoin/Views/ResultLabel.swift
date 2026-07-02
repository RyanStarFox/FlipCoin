import SwiftUI

struct ResultLabel: View {
    let result: Face?
    let skin: CoinSkin

    var body: some View {
        Group {
            if let result = result {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.secondary)

                    Text(result == .a ? skin.faceAText : skin.faceBText)
                        .font(.largeTitle.weight(.light))
                        .foregroundColor(.primary)

                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.secondary)
                }
                .transition(
                    .opacity
                    .combined(with: .scale(scale: 0.8))
                    .combined(with: .offset(y: 10))
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: result)
                .id("result-\(result.rawValue)") // force re-render for animation trigger
            } else {
                Text("Tap below to flip")
                    .font(.body.weight(.light))
                    .foregroundColor(.secondary)
            }
        }
    }
}
