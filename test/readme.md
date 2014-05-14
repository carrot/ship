# Tests
Because the test-suite communicates with external services, it will take a long time to run. Also, without publishing access keys to our own accounts, there is no way to make some of these tests run out of the box. Those tests are skipped by default

If you'd like to run all the tests, you need to copy the `ship*.opts.sample` files in the `test` directory, rename them to just `ship*.opts`, and fill in actual details for your account. Once you have filled in your details, the tests should be able to be run successfully. And don't worry, the tests will also remove any files that they deploy to any service once the test is complete.
