Cordova
----------

Wraps the Cordova CLI and builds your static site into a mobile app in the `cordova` directory.

### Config Values

- **package_name**: domain name of your app package, e.g. `com.awesomecompany.coolapp`
- **name**: name of the project
- **platforms**: a space-separated list of the platforms you want to build an app for, e.g. `ios android`
- **build_type**: (optional, defaults to "release") the build command argument, e.g. `cordova build --release`

### Important Notes:

This deployer is just a wrapper around Cordova. If you want to modify the project
any further than the settings that are provided here, do so in your `cordova/config.xml`

Cordova requires that you have all of the required SDK's installed on your machine
already for this to work - Android Studio for Android, xCode for iOS, etc.

This will build an APK for you, but it will not sign or zipalign it for you. That
is left up to you.
