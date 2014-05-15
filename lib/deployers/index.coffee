deployers = require('indx')(__dirname)

# disable deployers that haven't been finished yet
delete deployers['dropbox']
delete deployers['transport']
delete deployers['nodejitsu']
delete deployers['vps']

delete deployers['helper'] # this one isn't a deployer

module.exports = deployers
