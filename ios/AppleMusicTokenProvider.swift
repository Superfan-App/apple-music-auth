import Foundation
import MusicKit
import ExpoModulesCore

public final class AppleMusicTokenProvider {
    public init() {}
    
    public func getDeveloperToken(options: MusicTokenRequestOptions) async throws -> String {
        // Use DefaultMusicTokenProvider to fetch the developer token
        return try await DefaultMusicTokenProvider().developerToken(options: options)
    }
    
    public func getUserToken(for developerToken: String, options: MusicTokenRequestOptions) async throws -> String {
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
        
        // Use DefaultMusicTokenProvider to fetch the user token.
        do {
            return try await DefaultMusicTokenProvider().userToken(for: developerToken, options: options)
        } catch let error as MusicTokenRequestError {
            // Pass through MusicTokenRequestError
            throw error
        } catch {
            // Wrap other errors
            throw MusicTokenRequestError.userTokenRequestFailed
        }
    }
}
