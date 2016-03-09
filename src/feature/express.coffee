# Express (web server) interface feature module
#
# This feature add-on module enables dynamic web server interface
# generation and is used as a `component` of other feature interfaces
# such as [restjson](restjson.litcoffee) and
# [autodoc](autodoc.litcoffee).
#
# It utilizes the [express](http://expressjs.com) web server framework
# to dynamically instanticate the web server and makes itself available
# for higher-order features to utilize it for associating additional routing endpoints.

module.exports =
  name: 'express'
  description: 'Fast, unopionated, minimalist web framework (HTTP/HTTPS)'
  config:
    port: 5000
  run: (model, runtime) ->
    source = model.parent
    if runtime.express instanceof Function
      console.info "express: re-using passed-in instance".grey
      return runtime.express

    express = require 'express'
    errorhandler = require 'errorhandler'
    port = runtime.express ? @config.port
    app = (->
      env = process.env.NODE_ENV ? 'development'
      if env is 'production'
        @use errorhandler {dumpExceptions: off, showStack: off}
        # the following will prevent production instance from crash...
        process.on 'uncaughtException', (err) ->
          console.log 'ALERT.. caught exception', err, err?.stack
      else
        console.log "running in #{env} mode"
        @use errorhandler {dumpExceptions: on, showStack: on}
        @set 'json spaces', 2

      return this
    ).call express()

    console.info "express: listening on #{port}".grey
    return app: app, server: app.listen port
