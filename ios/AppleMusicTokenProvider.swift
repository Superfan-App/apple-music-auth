import Foundation
import MusicKit
import ExpoModulesCore

public final class AppleMusicTokenProvider: MusicUserTokenProvider, MusicDeveloperTokenProvider {
    public init() {}
    
    public func developerToken(options: MusicTokenRequestOptions) async throws -> String {
        // Use DefaultMusicTokenProvider to fetch the developer token, always ignoring cache
        let optionsWithNoCache = options.union(.ignoreCache)
        return try await DefaultMusicTokenProvider().developerToken(options: optionsWithNoCache)
    }
    
    public func userToken(for developerToken: String, options: MusicTokenRequestOptions) async throws -> String {
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
        
        // Use DefaultMusicTokenProvider to fetch the user token, always ignoring cache
        let optionsWithNoCache = options.union(.ignoreCache)
        do {
            return try await DefaultMusicTokenProvider().userToken(for: developerToken, options: optionsWithNoCache)
        } catch let error as MusicTokenRequestError {
            // Pass through MusicTokenRequestError
            throw error
        } catch {
            // Wrap other errors
            throw MusicTokenRequestError.userTokenRequestFailed
        }
    }
}
