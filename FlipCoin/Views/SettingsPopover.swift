import SwiftUI

struct SettingsPopover: View {
    @Binding var skin: CoinSkin
    @Binding var soundEnabled: Bool
    @Binding var hapticEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Header
            Text("Coin Skin")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 4)

            // Skin options
            VStack(spacing: 0) {
                ForEach(CoinSkin.allCases, id: \.self) { option in
                    Button(action: { skin = option }) {
                        HStack(spacing: 10) {
                            Image(systemName: option.symbolName)
                                .frame(width: 24)
                                .font(.system(size: 15))
                                .foregroundColor(skin == option ? .accentColor : .secondary)

                            Text(option.displayName)
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            if skin == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 9)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

            // Toggles
            VStack(spacing: 4) {
                Toggle(isOn: $soundEnabled) {
                    Label("Sound", systemImage: "speaker.wave.2")
                        .font(.body)
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 20)
                .padding(.vertical, 6)

                Toggle(isOn: $hapticEnabled) {
                    Label("Haptic Feedback", systemImage: "hand.tap")
                        .font(.body)
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }
        }
        .padding(.bottom, 20)
        .frame(width: 250)
    }
}
