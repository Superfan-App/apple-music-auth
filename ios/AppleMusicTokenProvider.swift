import Foundation
import MusicKit
import ExpoModulesCore

class AppleMusicTokenProvider: MusicUserTokenProvider, MusicDeveloperTokenProvider {
    private var developerTokenCache: String?
    private var userTokenCache: [String: String] = [:]
    
    // MARK: - Developer Token
    
    func developerToken(options: MusicTokenRequestOptions) async throws -> String {
        // If we have a cached token and we're not ignoring cache, return it
        if !options.contains(.ignoreCache), let cachedToken = developerTokenCache {
            return cachedToken
        }
        
        // In a real implementation, you would generate or fetch your developer token here
        // For now, we'll expect it to be provided through the module configuration
        guard let token = AppleMusicAuth.developerToken else {
            throw MusicTokenRequestError.developerTokenRequestFailed
        }
        
        // Cache the token
        developerTokenCache = token
        return token
    }
    
    // MARK: - User Token
    
    override func userToken(for developerToken: String, options: MusicTokenRequestOptions) async throws -> String {
        // Check authorization status first
        guard MusicAuthorization.currentStatus == .authorized else {
            throw MusicTokenRequestError.permissionDenied
        }
        
        // If we have a cached token and we're not ignoring cache, return it
        if !options.contains(.ignoreCache), let cachedToken = userTokenCache[developerToken] {
            return cachedToken
        }
        
        do {
            // Get the user token from MusicKit
            let token = try await super.userToken(for: developerToken, options: options)
            
            // Cache the token
            userTokenCache[developerToken] = token
            return token
        } catch {
            // Map MusicKit errors to our error types
            if let musicError = error as? MusicTokenRequestError {
                throw musicError
            } else {
                throw MusicTokenRequestError.userTokenRequestFailed
            }
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        developerTokenCache = nil
        userTokenCache.removeAll()
    }
} 