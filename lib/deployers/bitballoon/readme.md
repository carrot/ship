Bitballoon
----------

Bitballoon can easily be set up for continuous deployment off a github branch, which typically is the preferred method for deployment. However, if you want to set up the initial deploy, or prefer manually deploy rather than linking to github, this deployer should fit the bill.

### Config Values

- **name**: name of the site you want to deploy
- **access_token**: an oauth access token from bitballoon

### Generating an Access Token

Luckily, it's very simple to generate an access token without having to jump through the usual oauth hoops. To do so, log into your bitballoon account, and head over to the **Applications** menu item.

![Bitballoon Applications](http://cl.ly/Y0Xn/Screen%20Shot%202014-10-13%20at%2012.34.37%20PM.png)

Once on this page, generate a new **Personal Access Token** as such:

![Bitballoon Personal Access Token 1](http://cl.ly/Y0eT/Screen%20Shot%202014-10-13%20at%2012.28.43%20PM.png)

![Bitballoon Personal Access Token 2](http://cl.ly/XzyO/Screen%20Shot%202014-10-13%20at%2012.29.31%20PM.png)

![Bitballoon Personal Access Token 3](http://cl.ly/Y0hs/Screen%20Shot%202014-10-13%20at%2012.29.39%20PM.png)

Now just copy that token and add it to your `ship.conf` file, or just enter it in the command line prompt the first time you run `ship` for the site. And no, don't try to use the token in the image above, it's just there as an example and is not a valid token. Make your own tokens holmes.
