import { requireNativeModule, NativeModule } from "expo-modules-core";

import type {
  AppleMusicAuthStatus,
  TokenRequestOptions,
} from "./AppleMusicAuth.types";

export declare class AppleMusicAuthModule extends NativeModule {
  readonly getAuthorizationStatus: () => Promise<AppleMusicAuthStatus>;
  readonly requestAuthorization: () => Promise<AppleMusicAuthStatus>;

  // Token Management
  readonly setDeveloperToken: (token: string) => Promise<void>;
  readonly getDeveloperToken: (options: TokenRequestOptions) => Promise<string>;
  readonly getUserToken: (options: TokenRequestOptions) => Promise<string>;
  readonly clearTokenCache: () => void;
}

// This call loads the native module object from the JSI
export default requireNativeModule("AppleMusicAuth") as AppleMusicAuthModule;
