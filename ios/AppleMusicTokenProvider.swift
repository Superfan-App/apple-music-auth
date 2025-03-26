import Foundation
import MusicKit
import ExpoModulesCore

// Remove conformance to MusicUserTokenProvider and MusicDeveloperTokenProvider
public final class AppleMusicTokenProvider {
    public init() {}
    
    public func developerToken(options: MusicTokenRequestOptions) async throws -> String {
        // Always add .ignoreCache to the options.
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
        
        let optionsWithNoCache = options.union(.ignoreCache)
        do {
            return try await DefaultMusicTokenProvider().userToken(for: developerToken, options: optionsWithNoCache)
        } catch let error as MusicTokenRequestError {
            throw error
        } catch {
            throw MusicTokenRequestError.userTokenRequestFailed
        }
    }
}
