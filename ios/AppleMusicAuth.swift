import Foundation
import MusicKit
import ExpoModulesCore

enum AppleMusicAuthError: LocalizedError {
    case authorizationFailed
    case notAuthorized
    case tokenError(MusicTokenRequestError)
    case invalidDeveloperToken(String)
    
    var errorDescription: String? {
        switch self {
        case .authorizationFailed:
            return "Failed to get Apple Music authorization"
        case .notAuthorized:
            return "Not authorized to access Apple Music"
        case .tokenError(let error):
            switch error {
            case .developerTokenRequestFailed:
                return "developerTokenRequestFailed: \(error.errorDescription ?? "Failed to get developer token")"
            case .permissionDenied:
                return "permissionDenied: \(error.errorDescription ?? "Permission denied")"
            case .privacyAcknowledgementRequired:
                return "privacyAcknowledgementRequired: \(error.errorDescription ?? "Privacy acknowledgement required")"
            case .unknown:
                return "unknown: \(error.errorDescription ?? "Unknown error")"
            case .userNotSignedIn:
                return "userNotSignedIn: \(error.errorDescription ?? "User not signed in")"
            case .userTokenRequestFailed:
                return "userTokenRequestFailed: \(error.errorDescription ?? "Failed to get user token")"
            case .userTokenRevoked:
                return "userTokenRevoked: \(error.errorDescription ?? "User token revoked")"
            @unknown default:
                return "unknown: \(error.errorDescription ?? "Unknown error")"
            }
        case .invalidDeveloperToken(let reason):
            return "Invalid developer token: \(reason)"
        }
    }
    
    var failureReason: String? {
        if case .tokenError(let error) = self {
            return error.failureReason
        }
        return nil
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .tokenError(let error):
            return error.recoverySuggestion
        case .notAuthorized:
            return "Please authorize this app to access Apple Music in Settings"
        case .invalidDeveloperToken:
            return "Check your developer token configuration"
        default:
            return nil
        }
    }
}

@objc(AppleMusicAuth)
class AppleMusicAuth: NSObject {
    // MARK: - Static Properties
    static var developerToken: String?
    // Use the fixed token provider (without protocol conformance)
    private static let tokenProvider = AppleMusicTokenProvider()
    
    // MARK: - Authorization Status
    static func getAuthorizationStatus() -> String {
        let status = MusicAuthorization.currentStatus
        return authStatusToString(status)
    }
    
    // MARK: - Request Authorization
    static func requestAuthorization() async throws -> String {
        let status = await MusicAuthorization.request()
        return authStatusToString(status)
    }
    
    // MARK: - Token Management
    static func setDeveloperToken(_ token: String) throws {
        // Basic format validation (JWT has 3 parts separated by dots)
        let components = token.components(separatedBy: ".")
        guard components.count == 3 else {
            throw AppleMusicAuthError.invalidDeveloperToken("Invalid JWT format")
        }
        
        // Decode and validate expiration
        guard let payloadData = Data(base64Encoded: AppleMusicAuth.base64URLToBase64(components[1])),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let expiration = payload["exp"] as? TimeInterval else {
            throw AppleMusicAuthError.invalidDeveloperToken("Could not decode token payload")
        }
        
        let expirationDate = Date(timeIntervalSince1970: expiration)
        guard expirationDate > Date() else {
            throw AppleMusicAuthError.invalidDeveloperToken("Token has expired")
        }
        
        developerToken = token
    }
    
    static func getDeveloperToken() async throws -> String {
        // If a developer token was manually set, use that one
        if let token = developerToken {
            return token
        }
        
        // Otherwise, fetch from the token provider
        return try await tokenProvider.developerToken(options: .ignoreCache)
    }
    
    static func getUserToken() async throws -> String {
        // Check authorization status
        let status = MusicAuthorization.currentStatus
        guard status == .authorized else {
            throw AppleMusicAuthError.notAuthorized
        }
        
        do {
            let devToken = try await getDeveloperToken()
            return try await tokenProvider.userToken(for: devToken, options: .ignoreCache)
        } catch let error as MusicTokenRequestError {
            throw AppleMusicAuthError.tokenError(error)
        } catch {
            throw error
        }
    }
    
    // MARK: - Helper Methods
    private static func authStatusToString(_ status: MusicAuthorization.Status) -> String {
        switch status {
        case .authorized:
            return "authorized"
        case .denied:
            return "denied"
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        @unknown default:
            return "unknown"
        }
    }
    
    // Helper for base64URL to base64 conversion
    private static func base64URLToBase64(_ value: String) -> String {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        return base64
    }
}
