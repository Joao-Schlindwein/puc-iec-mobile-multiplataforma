module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      // Path alias @/ → ./src/
      ['module-resolver', { root: ['./src'], alias: { '@': './src' } }],
      // Reanimated PRECISA ser o último plugin
      'react-native-reanimated/plugin',
    ],
  };
};
