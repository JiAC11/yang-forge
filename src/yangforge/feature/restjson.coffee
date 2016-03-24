# REST/JSON interface feature module
#
# This feature add-on module enables dynamic REST/JSON interface
# generation based on available runtime `module` instances.
#
# It utilizes the underlying [express](express.litcoffee) feature add-on
# to dynamically create routing middleware and associates various HTTP
# method facilities according to the available runtime `module`
# instances.
express  = require 'express'
bp       = require 'body-parser'
passport = require 'passport'

module.exports = ->
  console.log "generating REST/JSON interface..."

  yrouter  = (require './restjson-router') this

  restjson = (->
    @use bp.urlencoded(extended:true), bp.json(strict:true), passport.initialize()

    @use yrouter, (req, res, next) ->
      # always send back contents of 'result' if available
      unless res.locals.result? then return next 'route'
      res.setHeader 'Expires','-1'
      # send AS-IS since natively JSON
      res.send res.locals.result
      next()

    # default log successful transaction
    @use (req, res, next) ->
      #req.forge.log?.info query:req.params.id,result:res.locals.result,
      # 'METHOD results for %s', req.record?.name
      next()

    # default 'catch-all' error handler
    @use (err, req, res, next) ->
      console.error err
      res.status(err.status ? 500).send error: switch
        when err instanceof Error then err.toString()
        else JSON.stringify err

    return this
  ).call express()

  console.log "restjson generation complete"
  @express?.then (res) ->
    console.info "restjson: binding to /restjson".grey
    res.app.use "/restjson", restjson
    return res

  return restjson
