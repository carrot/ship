Ship
----

Multi-platform deployment with node.

### Why should you care?

If you often need to deploy files to different platforms, or you have an app or library written in node and would like to give your users the ability to deploy files to a variety of platforms, ship is probably what you are looking for.

Ship is small library that deploys files smoothly to the platforms listed below:

- [Amazon S3](lib/deployers/s3)
- [Github Pages](lib/deployers/gh-pages)
- [Heroku](lib/deployers/heroku)
- [Nodejitsu](lib/deployers/nodejitsu)
- [FTP](lib/deployers/ftp)
- [Dropbox](lib/deployers/dropbox)
- [Linux VPS](lib/deployers/vps)

Ship is also built on the adapter pattern, so if there's another platforms you'd like to deploy to, the project structure is easy to understand, and you can write a deployer, send a pull request, and we'd be happy to include it.

### Installation

`npm install ship -g`

### Usage

If you are using ship directly for your own deployments, its primary interface is through the command line. If you'd like to integrate it into your node app, skip to the section below on the javascript API.

The command line interface is simple -- just follow the format below

```
ship /path/to/folder deployer
```

For example, if I wanted to ship my desktop via ftp to my server (why? no idea), I could run `ship /Users/jeff/Desktop ftp`. Ship would then prompt me for authentication details if needed, and send the files off to their destination. It will also place a file called `ship.conf` in the root of the folder you shipped, and if you have a gitignore, add it to your gitignore because you don't want to commit your sensitive information. Next time you ship it, you won't need to enter your details because they are already saved to that file.

After the first time running `ship` on a folder, you can skip the deployer name if you'd like to deploy to the same target. If you have deployed the same folder to multiple targets and you run it without the deployer argument, ship will deploy to all targets.

Finally, if you are inside the folder you want to deploy, you can run ship without the path argument. If you name your folder the same thing as one of the deployers, things will get confused, so don't do that please.

Available deployers are as such:

- Amazon s3 - `s3`
- Github Pages - `gh-pages`
- Heroku - `heroku`
- Nodejitsu - `nodejitsu`
- FTP - `ftp`
- Dropbox - `dropbox`
- Linux VPS - `vps`

### ship.conf

This is a simple file used by ship to hold on to config values for various platforms. It's a yaml file and is quite straightforward. An example might look like this, if it was configured for amazon s3.

```
s3:
  access_key: 'xxxx'
  secret_key: 'xxxx'
```

If there are other network configs, they appear namespaced under the deployer name in a similar manner.

If you want to deploy to multiple environments, you can do this. Just drop an environment name after "ship" and before ".conf" like this: `ship.staging.conf`, and provide the environment in your command, like this `ship --env staging`, and ship will look for the appropriate environment file and use that.

### Javascript API

The interface is fairly straightforward. An example is below:

```js
var ship = require('ship'),
    s3 = ship['s3'],
    q = require('q');

// first, you might want to make sure the deployer
// has been configured. this means that there's
// a yaml file at the project root called `ship.conf`
// with the relevant config details.

if (!s3.configured) {

  // you can manually enter config values

  s3.configure({
    token: 'xxxx',
    secret: 'xxxx'
  });

  // or you can use ship's command line prompt to collect it
  // which returns a callback or promise.
  // if there is no `ship.conf` file present, this command
  // will create one and attempt to add it to `.gitignore`

  s3.configPrompt(function(err){
    if (err) return console.error(err);
    console.log('configured');
  });

}

// to actually deploy, just call .deploy().
// you can use a callback function so you know when it's done

s3.deploy('path/to/folder', function(err, res){
  if (err) return console.error(err);
  console.log('successfully deployed!');
  console.log(res);
});

// ship also returns a promise you can use if you'd like

s3.deploy('path/to/folder')
  .catch(function(err){ console.error(err); })
  .done(function(res){
    console.log('successfully deployed!');
    console.log(res);
  });

```

So in summary, require `ship`, get the deployer name you are after, make sure it's configured, run `deploy` and pass it a path to the file or folder you want to deploy, and get feedback with a callback or promise.
