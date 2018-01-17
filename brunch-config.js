exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: 'js/app.js',
      order: {
        before: [
          'web/static/vendor/jquery.min.js',
          'web/static/vendor/semantic/semantic.js'
        ]
      }

      // To use a separate vendor.js bundle, specify two files path
      // http://brunch.io/docs/config#-files-
      // joinTo: {
      //  "js/app.js": /^(web\/static\/js)/,
      //  "js/vendor.js": /^(web\/static\/vendor)|(deps)/
      // }
      //
      // To change the order of concatenation of files, explicitly mention here
      // order: {
      //   before: [
      //     "web/static/vendor/js/jquery-2.1.1.js",
      //     "web/static/vendor/js/bootstrap.min.js"
      //   ]
      // }
    },
    stylesheets: {
      joinTo: 'css/app.css',
      order: {
        after: ['web/static/css/app.css'] // concat app.css last
      }
    },
    templates: {
      joinTo: 'js/app.js'
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/web/static/assets". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(web\/static\/(assets|vendor\/semantic\/assets))/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: [
      'web/static',
      'web/elm/src'
    ],

    // Where to compile files to
    public: 'priv/static'
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/web\/static\/vendor/]
    },
    elmBrunch: {
      executablePath: '../../node_modules/elm/binwrappers',
      elmFolder: 'web/elm',
      mainModules: ['src/MySpotifyGroomer.elm'],
      outputFolder: '../static/vendor'
    }
  },

  modules: {
    autoRequire: {
      'js/app.js': ['web/static/js/app']
    }
  },

  npm: {
    enabled: true
  }
};
