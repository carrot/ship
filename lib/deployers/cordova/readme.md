Cordova
----------

Wraps the Cordova CLI and builds your static site into a mobile app in the `cordova` directory.

## Config Values
- **package_name**: domain name of your app package, e.g. `com.awesomecompany.coolapp`
- **name**: name of the project, e.g. `CoolApp`
- **platforms**: a space-separated list of the platforms you want to build an app for, e.g. `ios android`
- **build_type**: (optional, defaults to "release") the build command argument, e.g. `cordova build --release`

## Important Notes:
### Remember to add the Cordova Javascript
This deployer will generate a new Cordova project and overwrite it's `www` directory
with the contents of your `root` directory. This means that you will need to add this
before any scripts that come before your closing body tag:

```html
<script type="text/javascript" src="cordova.js"></script>
```

### Other Configuration
This deployer is just a wrapper around Cordova. If you want to modify the project
any further than the settings that are provided here, do so in your `cordova/config.xml`

### Platform Dependencies
Cordova requires that you have all of the required SDK's installed on your machine
already for this to work - Android Studio for Android, xCode for iOS, etc.

### Sign & Zipalign
This will build an APK for you, but it will not sign or zipalign it for you. That
is left up to you.

### Using Roots?
If you're using [Roots](https://github.com/jenius/roots) then you will need to
add `cordova` and `cordova/**` to your `ignores` array in `app.coffee` to prevent
recursive file generation. Failing to do so will likely result in very slow emulators!

### Help! My CSS and Images aren't working!
Yeah, well, that's Cordova for you... The fix is to make sure that all
your `link` elements have a `type="text/css"` attribute and then ensure
that all your paths look like this: `css/index.css` and not like this: `/css/index.css` -
it's an annoying tradeoff, but there are build tools that can convert these
to absolute paths for you automatically, check out some Gulp/Grunt plugins or the like.
