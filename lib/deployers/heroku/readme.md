Heroku
------

Pushes to [heroku](https://heroku.com) directly through heroku's platform API, avoiding the necessity to interact with git or the command line. Only requires an API token for auth, which you can easily grab from your account page on heroku.

### Config Values

- **name**: what you want to name the project on heroku
- **api_key**: heroku api key. get this from your [account page](https://dashboard.heroku.com/account)
- **config**: heroku configuration variables. pass in an object
