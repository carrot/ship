deployers = require('indx')(__dirname)

# disable deployers that haven't been finished yet
delete deployers['dropbox']
delete deployers['heroku']
delete deployers['nodejitsu']
delete deployers['vps']

module.exports = deployers
