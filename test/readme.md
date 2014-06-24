Running the Tests
-----------------

As you can probably guess, tests for a library like this are immensely difficult. Testing just our code is not enough, we need to run a full deploy on each platform and ensure that the deploy went smoothly in order to verify that things are working correctly. In many cases, we need to run more than one deploy because there are edge cases that must be tested as well.

This means two things: first, that the test suite takes a long time to run, and second that without publishing access keys to our own accounts, there was no way to make these tests run out of the box for contributors.

If you'd like to run the tests, you need to copy the `ship.conf.sample` files in the `fixtures/deployers/**` directories, rename them to just `ship.conf`, and fill in actual details for your account. Once you have filled in your details, the tests should be able to be run successfully. And don't worry, the tests will also remove any files that they deploy to any service once the test is complete.
