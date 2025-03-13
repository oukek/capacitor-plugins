// Configuration for your app
// https://v2.quasar.dev/quasar-cli-vite/quasar-config-file

import { defineConfig } from '#q-app/wrappers';

export default defineConfig((/* ctx */) => {
  return {
    css: [
      'app.scss'
    ],
    extras: [
      'roboto-font',
      'material-icons',
    ],
    build: {
      target: {
        browser: [ 'es2022', 'firefox115', 'chrome115', 'safari14' ],
        node: 'node20'
      },

      typescript: {
        strict: true,
        vueShim: true
        // extendTsConfig (tsConfig) {}
      },

      vueRouterMode: 'hash', // available values: 'hash', 'history'
      // vueRouterBase,
      // vueDevtools,
      // vueOptionsAPI: false,

      // rebuildCache: true, // rebuilds Vite/linter/etc cache on startup

      // publicPath: '/',
      // analyze: true,
      // env: {},
      // rawDefine: {}
      // ignorePublicFolder: true,
      // minify: false,
      // polyfillModulePreload: true,
      // distDir

      // extendViteConf (viteConf) {},
      // viteVuePluginOptions: {},

      vitePlugins: [
        ['vite-plugin-checker', {
          vueTsc: true,
          eslint: {
            lintCommand: 'eslint -c ./eslint.config.js "./src*/**/*.{ts,js,mjs,cjs,vue}"',
            useFlatConfig: true
          }
        }, { server: false }]
      ]
    },
    devServer: {
      open: false // opens browser window automatically
    },
    framework: {
      config: {},
      plugins: []
    },
    animations: [],
    ssr: {
      prodPort: 3000,
      middlewares: [
        'render' // keep this as last one
      ],
      pwa: false
    },

    pwa: {
      workboxMode: 'GenerateSW' // 'GenerateSW' or 'InjectManifest'
    },

    cordova: {
    },
    capacitor: {
      hideSplashscreen: true,
      capacitorPlugins: [
        '@oukek/capacitor-photo',
      ]
    },

    electron: {
      preloadScripts: [ 'electron-preload' ],
      inspectPort: 5858,
      bundler: 'packager', // 'packager' or 'builder'
      packager: {
      },

      builder: {
        appId: 'example'
      }
    },

    bex: {
      extraScripts: []
    }
  }
});
