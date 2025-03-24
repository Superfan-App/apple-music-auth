import Foundation
import MusicKit
import ExpoModulesCore

public final class AppleMusicTokenProvider {
    private var developerTokenCache: String?
    private var userTokenCache: [String: String] = [:]
    
    public init() {}
    
    public func cachedDeveloperToken(options: MusicTokenRequestOptions) async throws -> String {
        // Return cached token if available and caching is not ignored
        if !options.contains(.ignoreCache), let cachedToken = developerTokenCache {
            return cachedToken
        }
        
        // Use DefaultMusicTokenProvider to fetch the developer token.
        let token = try await DefaultMusicTokenProvider().developerToken(options: options)
        developerTokenCache = token
        return token
    }
    
    public func cachedUserToken(for developerToken: String, options: MusicTokenRequestOptions) async throws -> String {
        // Ensure user is authorized
        let authStatus = MusicAuthorization.currentStatus
        guard authStatus == .authorized else {
            // Map to appropriate MusicTokenRequestError
            switch authStatus {
            case .denied:
                throw MusicTokenRequestError.permissionDenied
            case .notDetermined:
                throw MusicTokenRequestError.userNotSignedIn
            case .restricted:
                throw MusicTokenRequestError.privacyAcknowledgementRequired
            default:
                throw MusicTokenRequestError.unknown
            }
        }
        
        // Return cached user token if available
        if !options.contains(.ignoreCache), let cachedToken = userTokenCache[developerToken] {
            return cachedToken
        }
        
        // Use DefaultMusicTokenProvider to fetch the user token.
        do {
            let token = try await DefaultMusicTokenProvider().userToken(for: developerToken, options: options)
            userTokenCache[developerToken] = token
            return token
        } catch let error as MusicTokenRequestError {
            // Pass through MusicTokenRequestError
            throw error
        } catch {
            // Wrap other errors
            throw MusicTokenRequestError.userTokenRequestFailed
        }
    }
    
    public func clearCache() {
        developerTokenCache = nil
        userTokenCache.removeAll()
    }
}
