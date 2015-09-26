# BELOW is a bit HACKISH
if /bin\/yfc$/.test require?.main?.filename
  if process.env.yfc_debug?
    unless console._prefixes?
      (require 'clim') '[forge]', console, true
  else
    console.log = ->

promise = require 'promise'
synth   = require 'data-synth'
yaml    = require 'js-yaml'
coffee  = require 'coffee-script'
path    = require 'path'
fs      = require 'fs'
url     = require 'url'
needle  = require 'needle'
indent  = require 'indent-string'

prettyjson = require 'prettyjson'
Compiler   = require './yang-compiler'

class Forge extends Compiler
  require: require

  class Spark extends synth.Store
    render: (data, opts={}) ->
      switch opts.format
        when 'json' then JSON.stringify data, 2
        when 'yaml' then prettyjson.render data, opts
        else data

    info: (options={}) ->
      summarize = (what) ->
        (synth.objectify k, v.description for k, v of what)
        .reduce ((a,b) -> synth.copy a, b), {}
      
      info = @constructor.extract 'name', 'description', 'license', 'keywords'
      for name, schema of @constructor.get 'schema.module'
        info.schema = do (schema, options) ->
          keys = [
            'name', 'prefix', 'namespace', 'description', 'revision', 'organization', 'contact'
            'include', 'import'
          ]
          meta = synth.extract.apply schema, keys
          return meta
        info.features   = summarize schema.feature if schema.feature?
        info.typedefs   = summarize schema.typedef if schema.typedef?
        info.operations = summarize schema.rpc     if schema.rpc?
        break; # just return ONE...

      return @render info, options

    enable: (name, options) ->
      @feature[name] ?= (@meta "feature.#{name}")?.construct? options

    disable: (name) ->
      @feature[name]?.destroy?()
      delete @feature[name]

    run: (features...) ->
      options = features
        .map (e) -> synth.objectify e, on
        .reduce ((a, b) -> synth.copy a, b, true), {}

      (@access @meta 'main').invoke 'run', options: options
      .catch (e) -> console.error e

    toString: -> "Spark:#{@meta 'name'}"

  # NOT the most efficient way to do it...
  genSchema: (options={}) ->
    
    fetch = (input, opts) ->
      try
        try
          data = fs.readFileSync (path.resolve opts.pkgdir, input), 'utf-8'
          pkgdir = path.dirname (path.resolve opts.pkgdir, input)
        catch
          data = fs.readFileSync (path.resolve input), 'utf-8'
          pkgdir = path.dirname (path.resolve input)
      catch then data = input
      return [ data, pkgdir ]
    
    yaml.Schema.create [
      new yaml.Type '!coffee/function',
        kind: 'scalar'
        resolve:   (data) -> typeof data is 'string'
        construct: (data) -> coffee.eval data
        predicate: (obj) -> obj instanceof Function
        represent: (obj) -> obj.toString()
      new yaml.Type '!yang',
        kind: 'mapping'
        resolve:   (data={}) ->
          # preprocessing should also validate if context available
          #@preprocess data
          typeof data.module is 'object'
        construct: (data) -> data
      new yaml.Type '!yang/extension',
        kind: 'mapping'
        resolve:   (data={}) -> true
        construct: (data) -> data
      new yaml.Type '!json',
        kind: 'scalar'
        resolve:   (data) -> typeof data is 'string'
        construct: (data) =>
          console.log "processing !json using: #{data}"
          [ data, pkgdir ] = fetch data, options
          @parse data, format: 'json'
      new yaml.Type '!yang/schema',
        kind: 'scalar'
        resolve:   (data) -> typeof data is 'string' 
        construct: (data) =>
          console.log "processing !yang/schema using: #{data}"
          [ data, pkgdir ] = fetch data, options
          options.pkgdir ?= pkgdir if pkgdir?
          @parse data, format: 'yang', options
      new yaml.Type '!yaml/schema',
        kind: 'scalar'
        resolve:   (data) -> typeof data is 'string'
        construct: (data) =>
          console.log "processing !yaml/schema using: #{data}"
          [ data, pkgdir ] = fetch data, options
          options.pkgdir ?= pkgdir if pkgdir?
          @parse data, format: 'yaml', pkgdir: pkgdir
      new yaml.Type '!yfx',
        kind: 'scalar'
        resolve:   (data) -> typeof data is 'string'
        construct: (data) =>
          console.log "processing !yfx executable archive (just treat as YAML for now)"
          [ data, pkgdir ] = fetch data, options
          options.pkgdir ?= pkgdir if pkgdir?
          @parse data, format: 'yaml', pkgdir: pkgdir
    ]

  parse: (source, opts={}) ->
    return source unless typeof source is 'string'
    
    input = source
    source = switch opts.format
      when 'yang' then super source
      when 'json' then JSON.parse source
      else yaml.load source, schema: @genSchema opts

    unless source? and typeof source is 'object'
      throw @error "unable to parse requested source data: #{input}"

    # XXX - below doesn't belong here...
    if source.dependencies?
      source.require = (arg) -> @dependencies[arg]
    return source

  preprocess: (source, opts={}) ->
    source = @parse source, opts if typeof source is 'string'
    return source unless source instanceof Object
    
    # determine whether source is YAML or YANG output... a bit hackish
    # but YANG parse output always has ONE primary root element
    # need a better way to know the actual VALUE of the source
    if Object.keys(source).length is 1
      source = schema: source

    if source.schema?
      source.parent = @source
      source.pkgdir = opts.pkgdir ? @source?.pkgdir
      source.schema = super source.schema, source if source.schema?
      delete source.parent
    return source

  compile: (source, opts={}) ->
    source = @preprocess source, opts
    if source?.schema?
      try
        source.parent = @source
        model = super source.schema, source if source.schema?
        delete source.parent
        for own name of model
          source.main = name
          break; # should only be ONE here
        # metadata = synth.extract.apply source, [
        #   'name', 'description', 'license', 'keywords', 'schema',
        #   'extension', 'feature', 'typedef', 'main'
        # ]
        metadata = source # need to FIX...
        source = ((synth Spark, opts.hook) metadata).bind model
      finally
        delete source.parent
    return source

  # performs load of a target source, defaults to async: true but can be optionally set to false
  # allows 'source' as array but ONLY if async is true
  load: (source, opts={}, resolve, reject) ->
    unless opts.async is false
      return promise.all (@load x, opts for x in source) if source instanceof Array
      return @invoke arguments.callee, source, opts unless resolve? and reject?
    else resolve = (x) -> x
    source = @compile source, opts unless synth.instanceof source
    resolve switch
      when (synth.instanceof source) then new source (source.get 'config')
      else source

  # performs async import of a target source path, accepts 'source' as array
  # ALWAYS async, cannot be set to async: false
  import: (source, opts={}, resolve, reject) ->
    return promise.all (@import x, opts for x in source) if source instanceof Array
    return @invoke arguments.callee, source, opts unless resolve? and reject?

    return resolve source if source instanceof Spark

    opts.async = true
    url = url.parse source if typeof source is 'string'
    source = switch url.protocol
      when 'forge:'
        forgery = opts.forgery ? (@get 'yangforge.runtime.forgery') ? (@meta 'forgery')
        "#{forgery}/registry/modules/#{url.hostname}"
      when 'http:','https:'
        source
      when 'github:'
        "https://raw.githubusercontent.com/#{url.hostname}#{url.pathname}"
      else
        url.protocol = 'file:'
        url.pathname
    tag = switch (path.extname source)
      when '.yang' then '!yang/schema'
      when '.json' then '!json'
      when '.yaml' then '!yaml/schema'
      else '!yfx'

    switch url.protocol
      when 'file:'
        try resolve @load "#{tag} #{source}"
        catch err then reject err
      when 'forge:'
        # we initiate a TWO stage sequence, get metadata and then get binary
        needle.get source, (err, res) =>
          if err? or res.statusCode isnt 200
            return reject err ? "unable to retrieve #{source}"
          console.info res.body
          chksum = res.body.checksum
          needle.get "#{source}/data", (err, res) =>
            if err? or res.statusCode isnt 200
              return reject err ? "unable to retrieve #{source} binary data"
            # TODO: verify checksum
            resolve @load "#{tag} #{res.body}"
      else
        # here we use needle to get the remote content
        console.log "fetching remote content at: #{source}"
        needle.get source, (err, res) =>
          if err? or res.statusCode isnt 200 then reject err
          else resolve @load "#{tag} |\n#{indent res.body, ' ', 2}" 

  export: (input) ->
    console.assert input instanceof Object, "invalid input to export module"
    console.assert typeof input.name is 'string' and !!input.name,
      "need to pass in 'name' of the module to export"
    format = input.format ? 'json'
    m = switch
      when (synth.instanceof input) then input
      else @resolve 'module', input.name
    console.assert (synth.instanceof m),
      "unable to retrieve requested module #{input.name} for export"

    tosource = require 'tosource'

    obj = m.extract 'name', 'schema', 'map', 'extensions', 'importers', 'exporters', 'procedures'
    for key in [ 'extensions', 'importers', 'procedures' ]
      obj[key]?.toJSON = ->
        @[k] = tosource v for k, v of this when k isnt 'toJSON' and v instanceof Function
        this

    return switch format
      when 'json' then JSON.stringify obj

#
# self-forge using the yangforge.yaml schema
# 
module.exports = (new Forge).load '!yaml/schema yangforge.yaml',
  async: false
  pkgdir: __dirname
  hook: ->
    @mixin Forge
    @include source: @extract()

