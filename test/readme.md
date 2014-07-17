Running the Tests
-----------------

As you can probably guess, tests for a library like this are immensely difficult. Testing just our code is not enough, we need to run a full deploy on each platform and ensure that the deploy went smoothly in order to verify that things are working correctly. In many cases, we need to run more than one deploy because there are edge cases that must be tested as well.

This means two things: first, that the test suite takes a long time to run, and second that without publishing access keys to our own accounts, there was no way to make these tests run out of the box for contributors.

If you'd like to run the tests, you need to copy the `ship.conf.sample` files in the `fixtures/deployers/**` directories, rename them to just `ship.conf`, and fill in actual details for your account. Once you have filled in your details, the tests should be able to be run successfully. And don't worry, the tests will also remove any files that they deploy to any service once the test is complete, so you won't have any junk left over on whatever service you have authorized.

### Adding keys to travis config

If you are part of the core team working on ship and you are adding a new deployer, in order for it to work on travis, you'll need to add any private configuration information to the encrypted environment variables. This is a bit of a pain, since travis takes all the environment variables in a single string -- this means in order to add new ones, you'll also need all the existing ones to avoid breaking any other tests. If you work at carrot or are part of the core team, you can ask another maintainer for a copy of the file in which the testing keys are stored. If you are contributing, the core team will make a testing account and provide the keys to get travis passing, as long as everything is sound and working locally.

If you are part of core and looking to add environment variables, add to the string in the `.env` file, make sure you have the travis command line tool installed. You can install it with the following command:

```
$ gem install travis
```

Now, copy the contents of the `.env` file and from your command line, run

```
$ travis encrypt PASTE_HERE
```

It should return an encrypted string, which you can now paste into the `.travis.yml` file. Awesome, that's it! Tests should be passing now. If this is not the case, make sure to give a quick read to the [travis docs](http://docs.travis-ci.com/user/encryption-keys/#Note-on-escaping-certain-symbols), especially the section on escaping certain symbols.

EDIT: Travis will not encrypt strings longer than 128 chars with this method, there's a [ticket open here](https://github.com/travis-ci/travis.rb/issues/41) for this issue. We're working on finding alternatives.
