// plugin/src/types.ts

/**
 * Configuration options for the Apple Music OAuth module.
 * This should be provided in your app.config.js or app.json under the "plugins" section.
 * 
 * @example
 * ```json
 * {
 *   "expo": {
 *     "plugins": [
 *       [
 *         "@superfan-app/apple-music-auth",
 *         {
 *           "usageDescription": "We need access to Apple Music to see what you've been listening to"
 *         }
 *       ]
 *     ]
 *   }
 * }
 * ```
 */
export interface AppleMusicConfig {
  /**
   * Custom message that will be shown to users when requesting Apple Music access.
   * This appears in the permission dialog when requesting access to Apple Music.
   * If not provided, a default message will be used.
   * @example "We need access to Apple Music to see what you've been listening to"
   */
  usageDescription?: string;
}