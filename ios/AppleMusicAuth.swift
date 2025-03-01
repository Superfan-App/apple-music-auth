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
            return error.errorDescription
        case .invalidDeveloperToken(let reason):
            return "Invalid developer token: \(reason)"
        }
    }
}

@objc(AppleMusicAuth)
class AppleMusicAuth: NSObject {
    // MARK: - Static Properties
    static var developerToken: String?
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
    
    static func getDeveloperToken(ignoreCache: Bool = false) async throws -> String {
        let options: MusicTokenRequestOptions = ignoreCache ? .ignoreCache : []
        return try await tokenProvider.cachedDeveloperToken(options: options)
    }
    
    static func getUserToken(ignoreCache: Bool = false) async throws -> String {
        let options: MusicTokenRequestOptions = ignoreCache ? .ignoreCache : []
        // First get the developer token
        let devToken = try await getDeveloperToken(ignoreCache: ignoreCache)
        // Then get the user token using the renamed caching method
        return try await tokenProvider.cachedUserToken(for: devToken, options: options)
    }
    
    static func clearTokenCache() {
        tokenProvider.clearCache()
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
