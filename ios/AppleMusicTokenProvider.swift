import Foundation
import MusicKit
import ExpoModulesCore

public final class AppleMusicTokenProvider {
    private var developerTokenCache: String?
    private var userTokenCache: [String: String] = [:]
    
    public init() {}
    
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    public func cachedDeveloperToken(options: MusicTokenRequestOptions) async throws -> String {
        // Return cached token if available and caching is not ignored
        if !options.contains(.ignoreCache), let cachedToken = developerTokenCache {
            return cachedToken
        }
        
        do {
            // If running in simulator and no developer token is cached, throw a specific error
            if isSimulator && developerTokenCache == nil {
                throw AppleMusicAuthError.tokenError("Developer token requests are not supported in the simulator. Please provide a developer token through the AppleMusicAuthProvider.")
            }
            
            // Use DefaultMusicTokenProvider to fetch the developer token.
            let token = try await DefaultMusicTokenProvider().developerToken(options: options)
            developerTokenCache = token
            return token
        } catch {
            print("[AppleMusicAuth] Developer token error details: \(error)")
            if let musicKitError = error as? MusicKitError {
                print("[AppleMusicAuth] MusicKit error code: \(musicKitError)")
            }
            throw error
        }
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
