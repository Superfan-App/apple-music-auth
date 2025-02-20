import ExpoModulesCore
import MusicKit

public class AppleMusicAuthModule: Module {
    public func definition() -> ModuleDefinition {
        Name("AppleMusicAuth")
        
        Function("getAuthorizationStatus") { () -> String in
            return AppleMusicAuth.getAuthorizationStatus()
        }
        
        AsyncFunction("requestAuthorization") { () async throws -> String in
            return try await AppleMusicAuth.requestAuthorization()
        }
        
        AsyncFunction("setDeveloperToken") { (token: String) async throws in
            try AppleMusicAuth.setDeveloperToken(token)
        }
    }
} 