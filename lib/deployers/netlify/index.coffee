netlify = require 'netlify'
W       = require 'when'
node    = require 'when/node'
_       = require 'lodash'

# This is used to resolve a name to a netlify preview domain for site lookups
preview_domain = ".netlify.com"

module.exports = (root, config) ->
  d = W.defer()

  if not config.access_token then return d.reject('missing access_token!')
  client = netlify.createClient(access_token: config.access_token)

  W().with(root: root, client: client, config: config, d: d)
    .then(lookup)
    .then (site) -> if site then site else create.call(@)
    .then(deploy)
    .done (site) ->
      d.resolve
        deployer: 'netlify'
        url: site.url
        destroy: destroy.bind(@, site.site_id)
    , d.reject

  return d.promise

module.exports.config =
  required: ['name', 'access_token']

###*
 * Checks to see if your site is already on netlify or not. Returns either a
 * site object or undefined.
 * @return {Promise} promise for either undefined or a site object
###

lookup = ->
  id = if @config.name.indexOf(preview_domain) != -1
    @config.name
  else
    @config.name + preview_domain
  node.call(@client.site.bind(@client), id)

###*
 * Creates a new site on netlify with a given name.
 * @return {Promise} promise for a newly created site object
###

create = ->
  @d.notify("Creating '#{@config.name}' on netlify")
  node.call(@client.createSite.bind(@client), name: @config.name)

###*
 * Creates a new deploy for a given site with the contents of the root.
 * @param {Object} site - a bit object from netlify
 * @return {Promise} a promise for a finished deployment
###

deploy = (site) ->
  @d.notify("Deploying '#{@config.name}'")
  node.call(site.createDeploy.bind(site), dir: @root)
    .then (deploy) -> node.call(deploy.waitForReady.bind(deploy))

###*
 * Deletes a given site from netlify.
 * @param  {Object} site - a site object from netlify
 * @return {Promise} a promise for the deleted site
###

destroy = (id) ->
  node.call(@client.site.bind(@client), id)
  .then (site) -> node.call(site.destroy.bind(site))
