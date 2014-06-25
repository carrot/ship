describe 'heroku', ->

  it.skip 'deploys a basic site', (done) ->
    test_path = path.join(test_dir, 'deployers/heroku')
    new cmd.default([test_path]).run (err, res) =>
      if err then done(err)
      # do the actual test
      res.deployers[0].destroy(done)
