# Contributing to Ship

Hello there! First of all, thanks for being interested in ship and helping out. We all think you are awesome, and by contributing to open source projects, you are making the world a better place. That being said, there are a few ways to make the process of contributing code to ship smoother, detailed below:

### Filing Issues

If you are opening an issue about a bug, make sure that you include clear steps for how we can reproduce the problem. _If we can't reproduce it, we can't fix it_. If you are suggesting a feature, make sure your explanation is clear and detailed.

### Getting Set Up

- Clone the project down
- Make sure [nodejs](http://nodejs.org) has been installed and is above version `0.10.x`
- Run `npm install`
- Put in work

### Testing

This project is constantly evolving, and to ensure that things are secure and working for everyone, we need to have tests. If you are adding a new feature, please make sure to add a test for it. The test suite for this project uses [mocha](http://visionmedia.github.io/mocha/) and [should](https://github.com/visionmedia/should.js/)/

To run the test suite, make sure you have installed mocha (`npm install mocha -g`), then you can use the `npm test` or simply `mocha` command to run the tests.

### Code Style

To keep a consistant coding style in the project, we're using [Polar Mobile's guide](https://github.com/polarmobile/coffeescript-style-guide), with one difference begin that much of this project uses `under_scores` rather than `camelCase` for variable naming. For any inline documentation in the code, we're using [JSDoc](http://usejsdoc.org/).

### Commit Cleanliness

It's ok if you start out with a bunch of experimentation and your commit log isn't totally clean, but before any pull requests are accepted, we like to have a nice clean commit log. That means [well-written and clear commit messages](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html) and commits that each do something significant, rather than being typo or bug fixes.

If you submit a pull request that doesn't have a clean commit log, we will ask you to clean it up before we accept. This means being familiar with rebasing - if you are not, [this guide](https://help.github.com/articles/interactive-rebase) by github should help you to get started. And if you are still confused, feel free to ask!
