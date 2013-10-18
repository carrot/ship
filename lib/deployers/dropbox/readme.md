Dropbox
-------

### Config Values

**target**: folder that you would like to deploy _(optional)_    
**app_key**: app key from dropbox    
**app_secret**: app secret from dropbox

### Setup Instructions

In order to deploy to dropbox, you need to set up an application so that you can grant ship access to upload files your dropbox. This process is fairly straightforward, and is documented below:

1. Head over to the dropbox site and [create an app](https://www.dropbox.com/developers/apps/create)
2. Choose your app's options according to [these instructions](https://cloudup.com/cvgGA7mn3zx).
3. On the next screen, choose the folder name you want to deploy to.
4. Grab the keys and add them as config values (specified above)

Note that the first time you deploy, ship will display a popup window asking you to verify. This is normal.
