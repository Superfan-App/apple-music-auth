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
        guard MusicAuthorization.currentStatus == .authorized else {
            throw MusicTokenRequestError.permissionDenied
        }
        
        // Return cached user token if available
        if !options.contains(.ignoreCache), let cachedToken = userTokenCache[developerToken] {
            return cachedToken
        }
        
        // Use DefaultMusicTokenProvider to fetch the user token.
        let token = try await DefaultMusicTokenProvider().userToken(for: developerToken, options: options)
        userTokenCache[developerToken] = token
        return token
    }
    
    public func clearCache() {
        developerTokenCache = nil
        userTokenCache.removeAll()
    }
}
