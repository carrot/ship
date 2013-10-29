Running the Tests
-----------------

As you can probably guess, tests for a library like this are immensely difficult. Testing just our code is not enough, we need to run a full deploy on each platform and ensure that the deploy went smoothly in order to verify that things are working correctly. In many cases, we need to run more than one deploy because there are edge cases that must be tested as well.

This means two things: first, that the test suite takes a long time to run, and sedond that without publishing access keys to our own accounts, there was no way to make these tests run out of the box.

If you'd like to run the tests, you need to create a `credentials.yml` file in this directory. We have left a sample here for you to follow the format. Once you have filled in your details, the tests should be able to be run successfully. And don't worry, any app that the tests create on any account, it will also delete once the test has completed.
