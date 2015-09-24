# yang-compiler

The **yang-compiler** class provides support for basic set of
YANG schema modeling language by using the built-in *extension* syntax
to define additional schema language constructs.

The compiler only supports bare minium set of YANG statements and
should be used only to generate a new compiler such as [yangforge](./yangforge.coffee)
which implements the version 1.0 of the YANG language specifications.

    synth = require 'data-synth'

    class YangCompiler

      define: (type, key, value) ->
        exists = @resolve type, key, false
        switch
          when not exists?
            [ prefix..., key ] = key.split ':'
            if prefix.length > 0
              @source[prefix[0]] ?= {}
              base = @source[prefix[0]]
            else
              base = @source
            synth.copy base, synth.objectify "#{type}.#{key}", value
          when exists.constructor is Object
            synth.copy exists, value
        return undefined
        
      resolve: (type, key, warn=true) ->
        [ prefix..., key ] = key.split ':'
        source = @source
        while source?
          base = if prefix.length > 0 then source[prefix[0]] else source
          match = base?[type]?[key]
          return match if match?
          source = source.parent

        console.log "[resolve] unable to find #{type}:#{key}" if warn
        return undefined

      locate: (inside, path) ->
        return unless typeof inside is 'object' and typeof path is 'string'
        if /^\//.test path
          console.warn "[locate] absolute-schema-nodeid is not yet supported, ignoring #{path}"
          return
        [ target, rest... ] = path.split '/'
        for key, val of inside when val.hasOwnProperty target
          return switch
            when rest.length > 0 then @locate val[target], rest.join '/'
            else val[target]
        console.warn "[locate] unable to find '#{path}' within #{Object.keys inside}"
        return

      error: (msg, context) ->
        res = new Error msg
        res.name = 'CompileError'
        res.context = context
        return res

The `parse` function performs recursive parsing of passed in statement
and sub-statements and usually invoked in the context of the
originating `compile` function below.  It expects the `statement` as
an Object containing prf, kw, arg, and any substmts as an array.  It
currently does NOT perform semantic validations but rather simply
ensures syntax correctness and building the JS object tree structure.

      normalize = (obj) -> ([ obj.prf, obj.kw ].filter (e) -> e? and !!e).join ':'

      parse: (input, parser=(require 'yang-parser')) ->
        try
          input = (parser.parse input) if typeof input is 'string'
        catch e
          e.offset = 30 unless e.offset > 30
          offender = input.slice e.offset-30, e.offset+30
          offender = offender.replace /\s\s+/g, ' '
          throw @error "[yang-compiler:parse] invalid YANG syntax detected", offender

        console.assert input instanceof Object,
          "must pass in proper input to parse"

        params = 
          (YangCompiler::parse.call this, stmt for stmt in input.substmts)
          .filter (e) -> e?
          .reduce ((a, b) -> synth.copy a, b, true), {}
        params = null unless Object.keys(params).length > 0

        unless params?
          synth.objectify "#{normalize input}", input.arg
        else
          input.arg = input.arg.replace '.','_'
          synth.objectify "#{normalize input}.#{input.arg}", params

The `preprocess` function is the intermediary method of the compiler
which prepares a parsed output to be ready for the `compile`
operation.  It deals with any `include` and `extension` statements
found in the parsed output in order to prepare the context for the
`compile` operation to proceed smoothly.

      extractKeys = (x) -> if x instanceof Object then (Object.keys x) else [x].filter (e) -> e? and !!e

      fork: (f, args...) -> f?.apply? (new @constructor), args

      preprocess: (schema, source={}, scope) ->
        source.extension ?= source.parent?.extension
        console.assert source.extension instanceof Object,
          "cannot preprocess requested schema without source.extension scope"
        return @fork arguments.callee, schema, source, source.extension unless scope?
        @source = source

        schema = (YangCompiler::parse.call this, schema) if typeof schema is 'string'
        console.assert schema instanceof Object,
          "must pass in proper 'schema' to preprocess"
        
        # Here we go through each of the keys of the schema object and
        # validate the extension keywords and resolve these keywords
        # if constructors are associated with these extension keywords.
        for key, val of schema
          [ prf..., kw ] = key.split ':'
          unless kw of scope
            throw @error "invalid '#{kw}' extension found during preprocess operation", schema

          if key is 'extension'
            extensions = (extractKeys val)
            for name in extensions
              extension = if val instanceof Object then val[name] else {}
              @define 'extension', name, extension
            delete schema.extension
            console.log "[preprocess:#{source.name}] found #{extensions.length} new extension(s)"
            continue

          ext = @resolve 'extension', key
          unless (ext instanceof Object)
            throw @error "[preprocess:#{source.name}] encountered unresolved extension '#{key}'", schema
          constraint = scope[kw]

          unless ext.argument?
            # TODO - should also validate constraint for input/output
            YangCompiler::preprocess.call this, val, source, ext
            ext.preprocess?.call? this, key, val, schema
          else
            args = (extractKeys val)
            valid = switch constraint
              when '0..1','1' then args.length <= 1
              when '1..n' then args.length > 1
              else true
            unless valid
              throw @error "[preprocess:#{source.name}] constraint violation for '#{key}' (#{args.length} != #{constraint})", schema
            for arg in args
              params = if val instanceof Object then val[arg]
              argument = switch
                when typeof arg is 'string' and arg.length > 50
                  ((arg.replace /\s\s+/g, ' ').slice 0, 50) + '...'
                else arg
              source.name ?= arg if key in [ 'module', 'submodule' ]
              console.log "[preprocess:#{source.name}] #{key} #{argument} " + if params? then "{ #{Object.keys params} }" else ''
              params ?= {}
              YangCompiler::preprocess.call this, params, source, ext
              try
                ext.preprocess?.call? this, arg, params, schema
              catch e
                console.error e
                throw @error "[preprocess:#{source.name}] failed to preprocess '#{key} #{arg}'", schema

        return schema
        
The `compile` function is the primary method of the compiler which
takes in YANG schema input and produces JS output representing the
input schema as meta data hierarchy.

It accepts following forms of input
* YANG schema text string
* function that will return a YANG schema text string
* Object output from `parse`

The compilation process can compile any partials or complete
representation of the schema and recursively compiles the data tree to
return instantiated copy.

      compile: (schema, source={}, scope) ->
        return @fork arguments.callee, schema, source, true unless scope?
        @source = source
        
        schema = (schema.call this) if schema instanceof Function
        schema = (YangCompiler::preprocess.call this, schema, source) unless source.extension?
        console.assert schema instanceof Object,
          "must pass in proper 'schema' to compile"

        output = {}
        for key, val of schema
          continue if key is 'extension'

          ext = @resolve 'extension', key
          unless (ext instanceof Object)
            throw @error "[compile:#{source.name}] encountered unknown extension '#{key}'", schema

          # here we short-circuit if there is no 'construct' for this extension
          continue unless ext.construct instanceof Function

          unless ext.argument?
            console.log "[compile:#{source.name}] #{key} " + if val? then "{ #{Object.keys val} }" else ''
            children = YangCompiler::compile.call this, val, source, ext
            output[key] = ext.construct.call this, key, val, children, output
            delete output[key] unless output[key]?
          else
            for arg in (extractKeys val)
              params = if val instanceof Object then val[arg]
              console.log "[compile:#{source.name}] #{key} #{arg} " + if params? then "{ #{Object.keys params} }" else ''
              params ?= {}
              children = YangCompiler::compile.call this, params, source, ext
              try
                output[arg] = ext.construct.call this, arg, params, children, output
                delete output[arg] unless output[arg]?
              catch e
                console.error e
                throw @error "[compile:#{source.name}] failed to compile '#{key} #{arg}'", schema
        return output

Here we return the new `YangCompiler` class for import and use by
other modules.

    module.exports = YangCompiler
