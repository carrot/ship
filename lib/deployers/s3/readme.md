Amazon S3
---------

Pushes target to amazon s3, at a publicly available bucket intended for serving files over the internet. If you do not already have a bucket, one will be created for you.

### Config Values

- **access_key**: you can get this from the s3 account panel
- **secret_key**: you can get this from the s3 account panel
- **bucket**: _(optional)_ the name of your bucket, defaults to current folder name
- **region**: _(optional)_ region of your bucket, defaults to `us-east-1`

### Getting Keys

The AWS control panel is notoriously confusing, so here's a simple guide on how to get what you need from it. First, in order to skip a confusing maze of about 10 links in order to get there, [hit this link](https://console.aws.amazon.com/iam/home?#security_credential) to get to your security credentials page. Now drop down the "Access Keys" menu and copy out your access keys. Whoo, painless!
