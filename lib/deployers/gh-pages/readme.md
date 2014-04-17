# GitHub Pages
In order to use this deployer, your project must be using git, and you must have a remote branch called 'origin'. The deployer will switch to a branch called gh-pages, clear all source files, dump the target folder to the root, make a single commit, and push the branch to GitHub before changing back to the branch you were on previously.

## Config Values
 - `[branch='gh-pages']`
