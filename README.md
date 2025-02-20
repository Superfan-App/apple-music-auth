# @superfan-app/apple-music-auth

A modern Expo module for Apple Music authentication in React Native apps. This module provides seamless integration with MusicKit for Apple Music authentication and token management.

## Features

- 🎵 Complete Apple Music authentication via MusicKit
- 🔑 Developer and User token management
- 📱 iOS 15.0+ support via native SDK
- ⚡️ Modern Expo development workflow
- 🛡️ Secure token caching
- 🔧 TypeScript support
- 📝 Comprehensive error handling

## Installation

```bash
npx expo install @superfan-app/apple-music-auth
```

This module requires the Expo Development Client (not compatible with Expo Go):

```bash
npx expo install expo-dev-client
```

## Configuration

1. Set up Apple Music capabilities in your Xcode project

2. Obtain your Apple Music developer token from the [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list)

3. (Optional) Configure your app.json/app.config.js:

```json
{
  "expo": {
    "plugins": [
      [
        "@superfan-app/apple-music-auth",
        {
          "usageDescription": "We need access to Apple Music to personalize your experience"
        }
      ]
    ]
  }
}
```

If no configuration is provided, the module will use default settings:
- A default usage description message will be shown in the permission dialog
- iOS settings will be configured automatically for MusicKit compatibility

## Usage

1. Wrap your app with the provider:

```tsx
import { AppleMusicAuthProvider } from '@superfan-app/apple-music-auth';

export default function App() {
  return (
    <AppleMusicAuthProvider developerToken="your-developer-token">
      <MainApp />
    </AppleMusicAuthProvider>
  );
}
```

2. Use the hook in your components:

```tsx
import { useAppleMusicAuth } from '@superfan-app/apple-music-auth';

function MainScreen() {
  const { 
    authState,
    requestAuthorization,
    getUserToken,
    isAuthenticating,
    error
  } = useAppleMusicAuth();

  const handleAuth = async () => {
    try {
      const status = await requestAuthorization();
      if (status === 'authorized') {
        const userToken = await getUserToken();
        // Use the user token for API calls
      }
    } catch (err) {
      console.error('Authentication failed:', err);
    }
  };

  if (isAuthenticating) {
    return <ActivityIndicator />;
  }

  if (error) {
    return <Text>Error: {error.message}</Text>;
  }

  return (
    <View>
      <Text>Status: {authState.status}</Text>
      <Button onPress={handleAuth} title="Authenticate" />
    </View>
  );
}
```

## API Reference

### AppleMusicAuthProvider

Provider component that manages authentication state.

```tsx
<AppleMusicAuthProvider developerToken?: string>
  {children}
</AppleMusicAuthProvider>
```

Props:
- `developerToken`: Optional developer token to initialize the provider

### useAppleMusicAuth()

Hook for accessing authentication state and methods.

Returns:
- `authState: { status: string, developerToken?: string, userToken?: string }`
- `requestAuthorization(): Promise<string>` - Request user authorization
- `setDeveloperToken(token: string): void` - Set the developer token
- `getDeveloperToken(options?: TokenRequestOptions): Promise<string>` - Get the developer token
- `getUserToken(options?: TokenRequestOptions): Promise<string>` - Get the user token
- `clearTokenCache(): void` - Clear cached tokens
- `isAuthenticating: boolean` - Authentication in progress
- `error: AppleMusicAuthError | null` - Last error

### Authorization Status Types

Possible values for `authState.status`:
- `'authorized'` - User has granted access
- `'denied'` - User has denied access
- `'notDetermined'` - User hasn't been asked for permission
- `'restricted'` - Access is restricted
- `'unknown'` - Status cannot be determined

### Token Request Options

Options for token requests:
```typescript
interface TokenRequestOptions {
  ignoreCache?: boolean; // Force fetch new token
}
```

## Development Workflow

1. Clean installation:
```bash
npm install
npm run build
```

2. Clean build:
```bash
npx expo prebuild --clean
```

3. Run on iOS:
```bash
npx expo run:ios
```

## Troubleshooting

### Common Issues

1. "Cannot find native module 'AppleMusicAuth'":
   ```bash
   npx expo prebuild --clean
   npx expo run:ios
   ```

2. Build errors:
   ```bash
   npm run clean
   npm run build
   npx expo prebuild --clean
   ```

3. Authentication errors:
   - Verify your developer token
   - Check Apple Music capabilities in Xcode
   - Ensure proper entitlements
   - Check iOS version (requires 15.0+)

## Security

- Tokens are cached in memory
- Automatic token management
- Proper error handling and recovery
- Uses Apple's secure MusicKit framework

## Requirements

- Expo SDK 47+
- iOS 15.0+
- Node.js 14.0+
- Expo Development Client
