describe 's3'

  it.skip 'deploys a basic site to s3', (done) ->
    test_path = path.join(test_dir, 'deployers/s3')
    new cmd.default([test_path]).run (err, res) ->
      re = /(http:\/\/.*)/
      should.not.exist(err)
      # make sure it returned a url
      res.messages[0].should.match(re)
      # hit the url and make sure the site is up
      # and that the ignored file is not
      root_url = res.messages[0].match(re)[1]

      req_root = (cb) ->
        request root_url, (err, resp, body) ->
          should.not.exist(err)
          body.should.match /look ma, it worked/
          cb()

      req_ignore = (cb) ->
        request "#{root_url}/ignoreme.html", (err, resp, body) ->
          should.not.exist(err)
          body.should.not.match /i am a-scared/
          cb()

      async.parallel [req_root, req_ignore], ->
        # remove the testing bucket and finish
        res.deployers[0].destroy(done)
