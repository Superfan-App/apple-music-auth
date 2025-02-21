// src/index.tsx

import React, { useContext, useState, useCallback, useEffect } from "react";

import {
  AppleMusicAuthContext,
  AppleMusicAuthContextInstance,
  AppleMusicAuthState,
  AppleMusicAuthStatus,
  AppleMusicAuthError,
  TokenRequestOptions,
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

  // Initialize with developer token if provided
  useEffect(() => {
    if (developerToken) {
      const initializeDeveloperToken = async () => {
        try {
          await setDeveloperToken(developerToken);
        } catch (err) {
          console.error("[AppleMusicAuth] Failed to set developer token:", err);
        }
      };
      initializeDeveloperToken();
    }
  }, [developerToken]);

  // Check initial authorization status
  useEffect(() => {
    const checkInitialStatus = async () => {
      try {
        const status = await AppleMusicAuthModule.getAuthorizationStatus();
        setAuthState((prev) => ({ ...prev, status }));
      } catch (err) {
        console.error("[AppleMusicAuth] Error checking initial status:", err);
      }
    };
    checkInitialStatus();
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
          type: err instanceof Error && err.message.includes("Not authorized")
            ? "authorization_denied"
            : err instanceof Error && err.message.includes("Failed to get Apple Music authorization")
              ? "authorization_failed"
              : "authorization_error",
          message: err instanceof Error ? err.message : "Authorization failed",
          details: {
            error_code: err instanceof Error && err.message.includes("Not authorized")
              ? "not_authorized"
              : err instanceof Error && err.message.includes("Failed to get")
                ? "auth_failed"
                : "unknown",
            recoverable: err instanceof Error && !err.message.includes("Not authorized"), // Only recoverable if not explicitly denied
          },
        };

        setError(error);
        setIsAuthenticating(false);
        throw error;
      }
    }, []);

  const setDeveloperToken = useCallback(async (token: string) => {
    try {
      await AppleMusicAuthModule.setDeveloperToken(token);
      setAuthState((prev) => ({ ...prev, developerToken: token }));
    } catch (err) {
      console.error("[AppleMusicAuth] Developer token error:", err);

      const error: AppleMusicAuthError = {
        type: "token_error",
        message: err instanceof Error ? err.message : "Invalid developer token",
        details: {
          error_code: err instanceof Error && err.message.includes("Invalid JWT format")
            ? "invalid_format"
            : err instanceof Error && err.message.includes("Token has expired")
              ? "token_expired"
              : err instanceof Error && err.message.includes("Could not decode")
                ? "decode_failed"
                : "invalid_token",
          recoverable: false,
        },
      };

      setError(error);
      throw error;
    }
  }, []);

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
        throw err;
      }
    },
    [],
  );

  const getUserToken = useCallback(
    async (options?: TokenRequestOptions): Promise<string> => {
      try {
        const token = await AppleMusicAuthModule.getUserToken(options || {});
        setAuthState((prev) => ({ ...prev, userToken: token }));
        return token;
      } catch (err) {
        console.error("[AppleMusicAuth] User token error:", err);
        throw err;
      }
    },
    [],
  );

  const clearTokenCache = useCallback(() => {
    AppleMusicAuthModule.clearTokenCache();
    setAuthState((prev) => ({
      ...prev,
      developerToken: undefined,
      userToken: undefined,
    }));
  }, []);

  return (
    <AppleMusicAuthContextInstance.Provider
      value={{
        authState,
        requestAuthorization,
        setDeveloperToken,
        getDeveloperToken,
        getUserToken,
        clearTokenCache,
        isAuthenticating,
        error,
      }}
    >
      {children}
    </AppleMusicAuthContextInstance.Provider>
  );
}

export function useAppleMusicAuth(): AppleMusicAuthContext {
  const context = useContext(AppleMusicAuthContextInstance);
  if (!context) {
    throw new Error(
      "useAppleMusicAuth must be used within an AppleMusicAuthProvider",
    );
  }
  return context;
}

// Re-export types
export * from "./AppleMusicAuth.types";
