// src/AppleMusicAuth.types.ts

export type AppleMusicAuthStatus = 
  | 'authorized'
  | 'denied'
  | 'notDetermined'
  | 'restricted'
  | 'unknown';

export type TokenRequestOptions = {
  ignoreCache?: boolean;
};

export interface AppleMusicAuthError {
  type: string;
  message: string;
  details?: {
    error_code: string;
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
  clearTokenCache: () => void;
  isAuthenticating: boolean;
  error: AppleMusicAuthError | null;
}

// Create the React context with a default value of undefined
import { createContext } from 'react';
export const AppleMusicAuthContextInstance = createContext<AppleMusicAuthContext | undefined>(undefined); 