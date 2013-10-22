Github Pages
------------

In order to use this deployer, your project should be using git, and you should have a remote branch called 'origin' which is linked to github. The deployer will switch to a branch called gh-pages, clear all source files, dump the target folder to the root, make a single commit, and push the branch to github before changing back to the branch you were on previously.

### Config Values

**target**: the folder you want to deploy _(optional)_
