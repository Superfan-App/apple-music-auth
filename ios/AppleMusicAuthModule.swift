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

        AsyncFunction("getDeveloperToken") { (options: [String: Any]) async throws -> String in
            let ignoreCache = options["ignoreCache"] as? Bool ?? false
            return try await AppleMusicAuth.getDeveloperToken(ignoreCache: ignoreCache)
        }

        AsyncFunction("getUserToken") { (options: [String: Any]) async throws -> String in
            let ignoreCache = options["ignoreCache"] as? Bool ?? false
            return try await AppleMusicAuth.getUserToken(ignoreCache: ignoreCache)
        }

        AsyncFunction("clearTokenCache") { () async throws in
            AppleMusicAuth.clearTokenCache()
        }
    }
} 