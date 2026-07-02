import Foundation

enum CoinSkin: String, CaseIterable, Codable {
    case yesNo
    case ab
    case oneTwo
    case sunMoon

    var displayName: String {
        switch self {
        case .yesNo:   return "Yes / No"
        case .ab:      return "A / B"
        case .oneTwo:  return "1 / 2"
        case .sunMoon: return "☀️ / 🌙"
        }
    }

    var symbolName: String {
        switch self {
        case .yesNo:   return "checkmark.square"
        case .ab:      return "textformat.abc"
        case .oneTwo:  return "textformat.123"
        case .sunMoon: return "moon.stars"
        }
    }

    var faceAText: String {
        switch self {
        case .yesNo:   return "YES"
        case .ab:      return "A"
        case .oneTwo:  return "1"
        case .sunMoon: return "☀️"
        }
    }

    var faceBText: String {
        switch self {
        case .yesNo:   return "NO"
        case .ab:      return "B"
        case .oneTwo:  return "2"
        case .sunMoon: return "🌙"
        }
    }
}
