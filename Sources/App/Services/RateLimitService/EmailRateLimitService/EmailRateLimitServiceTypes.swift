import Foundation

protocol EmailRateLimitMessage: Codable {
    mutating func getMessage() -> String
}

enum EmailDailyRateLimitMessage: EmailRateLimitMessage {
    case authCreateAccount(limit: Int)
    case authLogin(limit: Int)

    mutating func getMessage() -> String {
        switch self {
        case let .authCreateAccount(limit):
            return
                "Reached limit of \(limit) account creation attempts for today. Try again in 24 hours."
        case let .authLogin(limit):
            return
                "Reached limit of \(limit) account login attempts for today. Try again in 24 hours."
        }
    }
    static func fromEmailMessageType(messageType: EmailMessageType, limit: Int)
        -> EmailDailyRateLimitMessage
    {
        switch messageType {
        case .authCreateAccount:
            return .authCreateAccount(limit: limit)
        case .authLogin:
            return .authLogin(limit: limit)
        }
    }
}

enum EmailIntervalRateLimitMessage: EmailRateLimitMessage {
    case authCreateAccount(seconds: Int)
    case authLogin(seconds: Int)

    func getMessage() -> String {
        switch self {
        case let .authCreateAccount(seconds):
            return "Too many account creation attempts. Try again in \(seconds) seconds."
        case let .authLogin(seconds):
            return "Too many login attempts. Try again in \(seconds) seconds."
        }
    }

    static func fromEmailMessageType(messageType: EmailMessageType, limit: Int)
        -> EmailIntervalRateLimitMessage
    {
        switch messageType {
        case .authCreateAccount:
            return .authCreateAccount(seconds: limit)
        case .authLogin:
            return .authLogin(seconds: limit)
        }
    }
}
