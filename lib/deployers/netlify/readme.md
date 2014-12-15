Netlify
----------

Netlify can easily be set up for continuous deployment off a github branch, which typically is the preferred method for deployment. However, if you want to set up the initial deploy, or prefer manually deploy rather than linking to github, this deployer should fit the bill.

### Config Values

- **name**: name of the site you want to deploy
- **access_token**: an oauth access token from netlify

### Generating an Access Token

You can easily generate an access token for netlify using their [CLI tool](https://github.com/netlify/netlify-cli).

- `npm install netlify-cli -g`
- `netlify open` - You just need to run any command in order to trigger the authentication flow with the Netlify website.
- Authorize the CLI client with your Netlify account
- `cat ~/.netlify/config` - You should see your access token in this file.
