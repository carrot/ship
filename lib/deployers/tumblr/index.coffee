Deployer = require '../../deployer'
request = require('request').defaults(jar: true)
$ = require 'cheerio'
path = require 'path'
fs = require 'fs'
_ = require 'lodash'
W = require 'when'

_errors =
  ACCESS_DENIED: 'Please verify your credentials are correct by signing into Tumblr via their web site.'

_urls =
  SIGN_IN: 'https://www.tumblr.com/login'

class Tumblr extends Deployer

  constructor: ->

    super()

    @configSchema.schema.email =
      type: 'string'
      required: true

    @configSchema.schema.password =
      type: 'string'
      required: true

    @configSchema.schema.blog =
      type: 'string'
      required: true

    @configSchema.schema.file =
      type: 'string'
      required: false
      default: 'index.html'

  deploy: (config) ->
    super config
    @getSignIn()
      .then(@parseSignIn.bind(@))
      .then(@signIn.bind(@))
      .then(@getCustomize.bind(@))
      .then(@deployTheme.bind(@))

  _customize: ->
    GET: "https://www.tumblr.com/customize/#{@_config.blog}"
    POST: "https://www.tumblr.com/customize_api/blog/#{@_config.blog}"

  src: ->
    fs.readFileSync path.join(@_config.projectRoot, @_config.file), 'utf8'

  getSignIn: ->
    _get _urls.SIGN_IN

  parseSignIn: (response) ->
    _parse _element(response, 'signup_form'),
      'user[email]': @_config.email
      'user[password]': @_config.password

  signIn: (data) ->
    _post _urls.SIGN_IN, form: data

  getCustomize: ->
    _post @_customize().GET

  deployTheme: (response) ->

    opts =
      json: true
      body:
        'user_form_key': _element(response, 'form_key').val()
        'custom_theme': @src()

    _post(@_customize().POST, opts)
      .then (response) ->
        unless response.statusCode is 200 then throw new Error _errors.ACCESS_DENIED

_get = (uri, options) ->
  _req uri, 'GET', options

_post = (uri, options) ->
  _req uri, 'POST', options

_element = (response, id) ->
  $("##{id}", response.body)

_parse = (form, attrs) ->
  data = {}
  form
    .find('input, textarea, select, keygen')
    .each -> data[@.attr('name')] = @.val()
  _.defaults data, attrs

_req = (uri, method, options) ->

  W.promise (resolve, reject) ->

    _defaults =
      uri: uri
      method: method
      followAllRedirects: true

    request _.defaults(_defaults, options), (error, response) ->
      if error then reject error
      resolve response

module.exports = Tumblr
