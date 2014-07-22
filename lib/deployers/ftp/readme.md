FTP
---

> **Note:** This deployer is not functional at the moment, it's a work in progress.

This deployer will push the target folder to the root specified in the configuration. This is not a zero-downtime deploy, and will clear the root folder's previous contents before pushing the new files, meaning if you are running a live site, it will be down for a few seconds.

### Config Values

**target**: folder that you would like to deploy _(optional)_
**host**: url to connect via FTP
**port**: port to connect through. default 21
**username**: self-explanitory
**password**: self-explanitory
**root**: path to the directory where you want to upload your site
