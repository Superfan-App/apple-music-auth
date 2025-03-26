// src/AppleMusicAuth.types.ts

// Create the React context with a default value of undefined
import { createContext } from "react";

export type AppleMusicAuthStatus =
  | "authorized"
  | "denied"
  | "notDetermined"
  | "restricted"
  | "unknown";

export type TokenRequestOptions = {
  ignoreCache?: boolean;
};

export type AppleMusicAuthErrorType =
  | "authorization_denied"
  | "authorization_failed"
  | "token_error"
  | "authorization_error";

export type AppleMusicAuthErrorCode =
  | "not_authorized"
  | "auth_failed"
  | "invalid_format"
  | "token_expired"
  | "decode_failed"
  | "invalid_token"
  | "unknown";

export interface AppleMusicAuthError {
  type: AppleMusicAuthErrorType;
  message: string;
  details?: {
    error_code: AppleMusicAuthErrorCode;
    recoverable: boolean;
  };
}

export interface AppleMusicAuthState {
  status: AppleMusicAuthStatus;
  developerToken?: string;
  userToken?: string;
}

export interface AppleMusicAuthContext {
  authState: AppleMusicAuthState;
  requestAuthorization: () => Promise<AppleMusicAuthStatus>;
  setDeveloperToken: (token: string) => Promise<void>;
  getDeveloperToken: (options?: TokenRequestOptions) => Promise<string>;
  getUserToken: (options?: TokenRequestOptions) => Promise<string>;
  isAuthenticating: boolean;
  error: AppleMusicAuthError | null;
  isInitialized: boolean;
}
export const AppleMusicAuthContextInstance = createContext<
  AppleMusicAuthContext | undefined
>(undefined);

export interface AppleMusicAuthHook extends AppleMusicAuthContext {
  requestAndGetToken: () => Promise<string>;
}

export interface AppleMusicAuthProviderProps {
  children: React.ReactNode;
  developerToken?: string;
  onAuthorizationChange?: (status: AppleMusicAuthStatus) => void;
  onError?: (error: AppleMusicAuthError) => void;
}
