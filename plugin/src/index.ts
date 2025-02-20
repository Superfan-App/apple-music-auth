// plugin/src/index.ts

import { type ConfigPlugin, createRunOncePlugin, withInfoPlist } from '@expo/config-plugins'
import { AppleMusicConfig } from './types.js'

const pkg = require('../../package.json');

const withAppleMusicConfiguration: ConfigPlugin<AppleMusicConfig> = (config, props = {}) => {
  return withInfoPlist(config, (config) => {
    // Required usage description
    config.modResults.NSAppleMusicUsageDescription = props.usageDescription || "This app requires access to Apple Music to play music and manage your library.";

    return config;
  });
};

const withIOSSettings: ConfigPlugin = (config) => {
  return withInfoPlist(config, (config) => {
    config.modResults.MinimumOSVersion = '15.0';
    config.modResults.EnableBitcode = false;
    config.modResults.SwiftVersion = '5.4';
    config.modResults.IphoneosDeploymentTarget = '15.0';

    return config;
  });
};

const withAppleMusicAuth: ConfigPlugin<AppleMusicConfig> = (config, props = {}) => {
  config = withAppleMusicConfiguration(config, props);
  config = withIOSSettings(config);

  return config;
};

export default createRunOncePlugin(withAppleMusicAuth, pkg.name, pkg.version);
