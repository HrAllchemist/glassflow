import Foundation

final class SettingsManager {
  static let shared = SettingsManager()

  private let defaults = UserDefaults.standard

  private enum Key: String {
    case geminiAPIKey
    case geminiSystemPrompt
    case deepgramAPIKey
    case webrtcSignalingURL
    case preferPhoneMic
  }

  private init() {}

  // MARK: - Gemini

  var geminiAPIKey: String {
    get { defaults.string(forKey: Key.geminiAPIKey.rawValue) ?? Secrets.geminiAPIKey }
    set { defaults.set(newValue, forKey: Key.geminiAPIKey.rawValue) }
  }

  var geminiSystemPrompt: String {
    get { defaults.string(forKey: Key.geminiSystemPrompt.rawValue) ?? GeminiConfig.defaultSystemInstruction }
    set { defaults.set(newValue, forKey: Key.geminiSystemPrompt.rawValue) }
  }

  // MARK: - Deepgram

  var deepgramAPIKey: String {
    get { defaults.string(forKey: Key.deepgramAPIKey.rawValue) ?? Secrets.deepgramAPIKey }
    set { defaults.set(newValue, forKey: Key.deepgramAPIKey.rawValue) }
  }

  // MARK: - Audio

  var preferPhoneMic: Bool {
    get { defaults.object(forKey: Key.preferPhoneMic.rawValue) as? Bool ?? false }
    set { defaults.set(newValue, forKey: Key.preferPhoneMic.rawValue) }
  }

  // MARK: - WebRTC

  var webrtcSignalingURL: String {
    get { defaults.string(forKey: Key.webrtcSignalingURL.rawValue) ?? Secrets.webrtcSignalingURL }
    set { defaults.set(newValue, forKey: Key.webrtcSignalingURL.rawValue) }
  }

  // MARK: - Reset

  func resetAll() {
    for key in [Key.geminiAPIKey, .geminiSystemPrompt, .deepgramAPIKey, .webrtcSignalingURL, .preferPhoneMic] {
      defaults.removeObject(forKey: key.rawValue)
    }
  }
}
