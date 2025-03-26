// src/index.tsx

import React, { useContext, useState, useCallback, useEffect } from "react";

import {
  AppleMusicAuthContextInstance,
  AppleMusicAuthState,
  AppleMusicAuthStatus,
  AppleMusicAuthError,
  TokenRequestOptions,
  AppleMusicAuthHook,
} from "./AppleMusicAuth.types";
import AppleMusicAuthModule from "./AppleMusicAuthModule";

interface AppleMusicAuthProviderProps {
  children: React.ReactNode;
  developerToken?: string;
}

export function AppleMusicAuthProvider({
  children,
  developerToken,
}: AppleMusicAuthProviderProps): JSX.Element {
  const [authState, setAuthState] = useState<AppleMusicAuthState>({
    status: "notDetermined",
  });
  const [isAuthenticating, setIsAuthenticating] = useState(false);
  const [error, setError] = useState<AppleMusicAuthError | null>(null);
  const [isInitialized, setIsInitialized] = useState(false);

  // Enhance error mapping
  const mapNativeError = useCallback((err: unknown): AppleMusicAuthError => {
    if (err instanceof Error) {
      const errorMsg = err.message;

      // Authorization Errors
      if (errorMsg.includes("Not authorized")) {
        return {
          type: "authorization_denied",
          message: "User denied access to Apple Music",
          details: {
            error_code: "not_authorized",
            recoverable: false,
          },
        };
      }

      if (errorMsg.includes("Failed to get Apple Music authorization")) {
        return {
          type: "authorization_failed",
          message: "Failed to request Apple Music authorization",
          details: {
            error_code: "auth_failed",
            recoverable: true,
          },
        };
      }

      // Token Validation Errors
      if (
        errorMsg.includes("Invalid JWT format") ||
        errorMsg.includes("Could not decode token payload") ||
        errorMsg.includes("Token has expired")
      ) {
        const isExpired = errorMsg.includes("expired");

        return {
          type: "token_error",
          message: isExpired
            ? "Developer token has expired"
            : "Invalid developer token format",
          details: {
            error_code: isExpired ? "token_expired" : "invalid_format",
            recoverable: isExpired, // Only expired tokens are recoverable
          },
        };
      }

      // MusicTokenRequestError specific errors
      if (errorMsg.includes("developerTokenRequestFailed")) {
        return {
          type: "token_error",
          message: "Failed to get developer token",
          details: {
            error_code: "invalid_token",
            recoverable: true,
          },
        };
      }

      if (errorMsg.includes("userTokenRequestFailed")) {
        return {
          type: "token_error",
          message: "Failed to get user token",
          details: {
            error_code: "invalid_token",
            recoverable: true,
          },
        };
      }

      if (errorMsg.includes("userTokenRevoked")) {
        return {
          type: "authorization_denied",
          message: "User revoked Apple Music access",
          details: {
            error_code: "not_authorized",
            recoverable: true,
          },
        };
      }

      if (errorMsg.includes("userNotSignedIn")) {
        return {
          type: "authorization_failed",
          message: "User is not signed in to Apple Music",
          details: {
            error_code: "auth_failed",
            recoverable: true,
          },
        };
      }

      if (errorMsg.includes("privacyAcknowledgementRequired")) {
        return {
          type: "authorization_failed",
          message: "User needs to acknowledge privacy policy",
          details: {
            error_code: "auth_failed",
            recoverable: true,
          },
        };
      }

      if (errorMsg.includes("permissionDenied")) {
        return {
          type: "authorization_denied",
          message: "Permission to access Apple Music was denied",
          details: {
            error_code: "not_authorized",
            recoverable: true,
          },
        };
      }
    }

    // Default error for unknown cases
    return {
      type: "authorization_error",
      message: err instanceof Error ? err.message : "An unknown error occurred",
      details: {
        error_code: "unknown",
        recoverable: false,
      },
    };
  }, []);

  const requestAuthorization =
    useCallback(async (): Promise<AppleMusicAuthStatus> => {
      try {
        console.log("[AppleMusicAuth] Starting authorization request");
        setIsAuthenticating(true);
        setError(null);

        const status = await AppleMusicAuthModule.requestAuthorization();
        setAuthState((prev) => ({ ...prev, status }));
        setIsAuthenticating(false);

        return status;
      } catch (err) {
        console.error("[AppleMusicAuth] Authorization error:", err);

        const error: AppleMusicAuthError = {
          type:
            err instanceof Error && err.message.includes("Not authorized")
              ? "authorization_denied"
              : err instanceof Error &&
                  err.message.includes(
                    "Failed to get Apple Music authorization",
                  )
                ? "authorization_failed"
                : "authorization_error",
          message: err instanceof Error ? err.message : "Authorization failed",
          details: {
            error_code:
              err instanceof Error && err.message.includes("Not authorized")
                ? "not_authorized"
                : err instanceof Error && err.message.includes("Failed to get")
                  ? "auth_failed"
                  : "unknown",
            recoverable:
              err instanceof Error && !err.message.includes("Not authorized"), // Only recoverable if not explicitly denied
          },
        };

        setError(error);
        setIsAuthenticating(false);
        throw error;
      }
    }, []);

  const setDeveloperToken = useCallback(
    async (token: string) => {
      try {
        await AppleMusicAuthModule.setDeveloperToken(token);
        setAuthState((prev) => ({ ...prev, developerToken: token }));
      } catch (err) {
        console.error("[AppleMusicAuth] Developer token error:", err);
        const mappedError = mapNativeError(err);
        setError(mappedError);
        throw mappedError;
      }
    },
    [mapNativeError],
  );

  const getDeveloperToken = useCallback(
    async (options?: TokenRequestOptions): Promise<string> => {
      try {
        const token = await AppleMusicAuthModule.getDeveloperToken(
          options || {},
        );
        setAuthState((prev) => ({ ...prev, developerToken: token }));
        return token;
      } catch (err) {
        console.error("[AppleMusicAuth] Developer token error:", err);
        const mappedError = mapNativeError(err);
        setError(mappedError);
        throw mappedError;
      }
    },
    [mapNativeError],
  );

  const getUserToken = useCallback(
    async (options?: TokenRequestOptions): Promise<string> => {
      try {
        const token = await AppleMusicAuthModule.getUserToken(options || {});
        setAuthState((prev) => ({ ...prev, userToken: token }));
        return token;
      } catch (err) {
        console.error("[AppleMusicAuth] User token error:", err);
        const mappedError = mapNativeError(err);
        setError(mappedError);
        throw mappedError;
      }
    },
    [mapNativeError],
  );

  // Add initialization tracking
  useEffect(() => {
    const initialize = async () => {
      try {
        const status = await AppleMusicAuthModule.getAuthorizationStatus();
        setAuthState((prev) => ({ ...prev, status }));

        if (developerToken) {
          await setDeveloperToken(developerToken);
        }

        setIsInitialized(true);
      } catch (err) {
        setError(mapNativeError(err));
        setIsInitialized(true);
      }
    };

    initialize();
  }, [developerToken, setDeveloperToken, mapNativeError]);

  // Add proper loading state
  if (!isInitialized) {
    return <>{null}</>; // Or proper loading component
  }

  return (
    <AppleMusicAuthContextInstance.Provider
      value={{
        authState,
        requestAuthorization,
        setDeveloperToken,
        getDeveloperToken,
        getUserToken,
        isAuthenticating,
        error,
        isInitialized,
      }}
    >
      {children}
    </AppleMusicAuthContextInstance.Provider>
  );
}

export function useAppleMusicAuth(): AppleMusicAuthHook {
  const context = useContext(AppleMusicAuthContextInstance);

  if (context === undefined) {
    throw new Error(
      "useAppleMusicAuth must be used within an AppleMusicAuthProvider",
    );
  }

  const requestAndGetToken = useCallback(async () => {
    const status = await context.requestAuthorization();
    if (status === "authorized") {
      return context.getUserToken();
    }
    throw new Error("Authorization denied");
  }, [context]);

  return {
    ...context,
    requestAndGetToken,
  } as AppleMusicAuthHook;
}

// Re-export types
export * from "./AppleMusicAuth.types";
