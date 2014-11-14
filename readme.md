Ship
----

[![npm](http://img.shields.io/npm/v/ship.svg?style=flat)](https://badge.fury.io/js/ship) [![tests](http://img.shields.io/travis/carrot/ship/master.svg?style=flat)](https://travis-ci.org/carrot/ship) [![coverage](http://img.shields.io/coveralls/carrot/ship.svg?style=flat)](https://coveralls.io/r/carrot/ship) [![dependencies](http://img.shields.io/gemnasium/carrot/ship.svg?style=flat)](https://gemnasium.com/carrot/ship)

Multi-platform deployment with node.

> **Note:** This project is in early development, and versioning is a little different. [Read this](http://markup.im/#q4_cRZ1Q) for more details.

### Why should you care?

If you often need to deploy files quickly to bunch of different platforms, or you have an app or library written in node and would like to give your users the ability to deploy files to a variety of platforms, ship is probably what you are looking for.

Ship is small library that deploys files smoothly to the platforms listed below:

- [Amazon S3](lib/deployers/s3)
- [Heroku](lib/deployers/heroku)
- [Github Pages](lib/deployers/gh-pages)
- [Bitballoon](lib/deployers/bitballoon)
- [Netlify](lib/deployers/netlify)

And many more coming soon, like:
- Linux VPS
- FTP
- Divshot
- Tumblr
- Dropbox
- SiteLeaf
- Email

Ship is also built on the adapter pattern, so if there's another platforms you'd like to deploy to, the project structure is easy to understand, and you can write a deployer, send a pull request, and we'd be happy to include it.

### Installation

`npm install ship -g`

### Usage

If you are using ship directly for your own deployments, its primary interface is through the command line. If you'd like to integrate it into your node app, skip to the section below on the [javascript API](#javascript-api).

The command line interface is simple -- just follow the format below

```
ship /path/to/folder -to deployer-name
```

For example, if I wanted to ship my desktop via s3 to my server (why? no idea), I could run `ship /Users/jeff/Desktop -to s3`. Ship would then prompt me for authentication details if needed, and send the files off to their destination. It will also place a file called `ship.conf` in the root of the folder you shipped, and if you have a gitignore, add it to your gitignore because you don't want to commit your sensitive information. Next time you ship it, you won't need to enter your details because they are already saved to that file.

After the first time running `ship` on a folder, you can skip the deployer name if you'd like to deploy to the same target. If you have deployed the same folder to multiple targets and you run it without the deployer argument, ship will deploy to all targets.

Finally, if you are inside the folder you want to deploy, you can run ship without the path argument. If you name your folder the same thing as one of the deployers, things will get confused, so don't do that please.

Available deployers are as such (linked to the documentation for authentication details, if needed):

- [Amazon S3](lib/deployers/s3) - `s3`
- [Github Pages](lib/deployers/gh-pages) - `gh-pages`
- [Heroku](lib/deployers/heroku) - `heroku`
- [Bitballoon](lib/deployers/bitballoon) - `bitballoon`
- [Netlify](lib/deployers/netlify) - `netlify`

### ship.conf

This is a simple file used by ship to hold on to config values for various platforms. It's a yaml file and is quite straightforward. An example might look like this, if it was configured for amazon s3.

```
s3:
  access_key: 'xxxx'
  secret_key: 'xxxx'
```

If there are other network configs, they appear namespaced under the deployer name in a similar manner.

If you want to deploy to multiple environments, you can do this. Just drop an environment name after "ship" and before ".conf" like this: `ship.staging.conf`, and provide the environment in your command, like this `ship -e staging`, and ship will look for the appropriate environment file and use that.

Finally, some deployers support built in 'ignores'. If you'd like to ignore a file or folder from the deploy process, just add an `ignore` array to the `ship.conf` file and fill it with [minimatch](https://github.com/isaacs/minimatch)-compatible strings. Any deployer that supports ignores will automatically ignore `ship*.conf` because you do not want to deploy that file, ever.

### Javascript API

The interface is fairly straightforward. An example is below. Please note that this is not a working example to be pasted into your project, it's a walkthrough of the public API at a high level.

```js
// First thing's first, let's create a new instance of Ship with the deployer we
// want to deploy with and the folder we want to be deployed.

var Ship = require('ship');
var project = new Ship({ root: 'path/to/folder', deployer: 's3' });

// First, you might want to make sure the deployer has been configured. This
// means that either there's a yaml file at the project root called `ship.conf`
// with the relevant config details for that deployer, or you have manually
// configured the instance. You can quickly check whether the deployer has been
// configured or not as such:

project.is_configured(); // returns a boolean

// If the deployer has been configured already as indicated above, you can skip
// the part below discussing manual configuration. If it has not however, you
// need to manually configure the deployer. You can do this by calling
// `configure` directly with the config values as such:

project.configure({ token: 'xxxx', secret: 'xxxx' });

// Or you can use ship's command line prompt to collect the info. This method is
// async and returns a promise.

project.config_prompt()
  .then(function(){ console.log('configured!'); });

// You might want to write the details to a `ship.conf` file once they have been
// collected so you don't need to continually input them. A convenience method
// will do this for you quickly, and try to add `ship.conf` to a `.gitignore` if
// there is one present, since you don't want to deploy or push it.

project.write_config();

// To actually deploy, just call project.deploy(). This returns a promise so
// you know when it's done. It also emits progress events along the way, since
// some deployments take a while and you might want to keep track of progress.

// If you want to deploy a directory different than the root you passed to the
// ship constructor, pass the path in as an argument to the deploy function. If
// you don't it will just deploy the root passed to the constructor.

project.deploy('path/to/folder/public')
  .progress(console.log.bind(console))
  .done(function(res){
    console.log('successfully deployed!');
    console.log(res);
  }, function(err){
    console.log('there was an error : (');
    console.log(err);
  });

// The response returned by the deployer contains as much useful information as
// possible. If possible, it will contain a `url`, so you can open up the site
// and check it on the spot. Each deployer has a slightly different response,
// you can find more specific details in that deployer's docs.
```

So in summary, require `ship`, initialize it with a folder and deployer, make sure it's configured, run `deploy`, then celebrate great success!

### License & Contributing

Ship is licensed under [MIT](license.md). See [contributing.md](contributing.md) for more information on contributing to ship.
