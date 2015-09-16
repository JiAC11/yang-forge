###
YANG Version 1.0 Extensions

This submodule implements the [RFC
6020](http://www.rfc-editor.org/rfc/rfc6020.txt) compliant language
extensions.  It is used by `yangforge` to produce a new compiler that
can then be used to compile any other v1 compatible YANG schema
definitions into JS code.

The extensions are handled by utilizing the `data-synth` library which
provides contextual mapping for different types of extension
statements to logical JS object representations.

Writing new extensions for YANG language is very straight-forward as
long as the context for the callback function to handle the extension
is well understood.  For more details, please refer to documentation
found inside the main `yangforge` project.
###

# normally should be require 'yangforge' but this is internal dependency
Forge = require 'yangforge'

module.exports = Forge.new module,
  before: ->
    # The following extensions declare externally shared metadata
    # definitions about the module.  They are not attached into
    # the generated module's configuration tree but instead
    # defined in the metadata section of the module only.
    @extension 'identity', (key, value) -> @scope.define 'identity', key, value
    @extension 'feature',  (key, value) -> @scope.define 'feature', key, value
    @extension 'grouping', (key, value) -> @scope.define 'grouping', key, value
    @extension 'typedef',  (key, value) -> @scope.define 'type', key, value

    @extension 'module', (key, value) ->
      exports = @scope.exports
      @set name: key, exports: exports
      @bind 'module', Forge.Model value, -> @set name: key, exports: exports
          
    @extension 'submodule', (key, value) ->
      @set name: key, exports: @scope.exports
      @merge value

    @extension 'import',     (key, value) -> @scope[key] = value?.extract? 'exports'
    @extension 'include',    (key, value) -> @mixin value
    @extension 'belongs-to', (key, value) -> @scope[value.get 'prefix'] = @scope

    @extension 'rpc', (key, value) ->
      @scope.define 'rpc', key, value
      #@hook key, value
      # do something

    @extension 'notification', (key, value) ->
      @scope.define 'notification', key, value
      #@hook key, value
      # do something

    @extension 'container', (key, value) -> @bind key, Forge.Object value
    @extension 'list',      (key, value) ->
      entry = Forge.Object (value.extract 'bindings')
      @bind key, (Forge.List value.unbind()).set type: entry
    @extension 'leaf-list', (key, value) -> @bind key, Forge.List value

    @extension 'leaf',      (key, value) ->
      @bind key, Forge.Property value, ->
        @set required: (@get 'mandatory') ? false

    # The following extensions makes alterations to the
    # configuration tree.  The `uses` statement references a
    # `grouping` node available within the context of the schema
    # being compiled to return the contents at the current `uses`
    # node context.  The `augment/refine` statements helps to
    # alter the containing statement with changes to the schema.
    @extension 'uses', (key, value) ->
      @mixin (@scope.resolve 'grouping', key), value
      for k, v  of value?.get? 'refine'
        orig = @unbind k ? Forge.Meta
        @bind k, (class extends orig).merge v
    @extension 'augment', (key, value) -> @bind key, value
    @extension 'refine',  (key, value) -> @merge "refine.#{key}", value

    @extension 'pattern', (value) -> @merge patterns: [ new RegExp value ]

    @extension 'enum', (key, value) ->
      val = value?.extract? 'value', 'description', 'reference', 'status'
      unless val?.value?
        @currentValue ?= 0
        val = value: @currentValue++
      val.value = (Number) val.value
      @set "enum.#{key}", val

    @extension 'type', (key, value) ->
      Type = Forge.Property (@scope.resolve 'type', key, false), ->
        @set yang: 'type', name: key
        if key is 'union'
          @merge value?.extract 'types'
        else
          @merge value
        unless (@get 'type')?
          @set type: key

        @set
          pattern: @get 'patterns'
          options: [ 'type', 'enum', 'types', 'pattern', 'range', 'length', 'normalizer', 'validator' ]
          normalizer: (value) ->
            console.log "#{@meta 'name'} normalizing '#{value}'"
            switch
              when @opts.type instanceof Function then new @opts.type value, this
              when @opts.type is 'enumeration' and typeof value is 'number'
                for key, val of @opts.enum
                  return key if val.value is value or val.value is "#{value}"
                value
              else @normalize value, type: @opts.type
          validator: (value=@value) ->
            console.log "#{@meta 'name'} validating '#{value}'"
            switch
              when @opts.type is 'string' and @opts.pattern?
                @opts.pattern.every (regex) -> regex.test value
              when @opts.type is 'enumeration' then @opts.enum?.hasOwnProperty value
              else @validate value, type: @opts.type
        @include
          valueOf: -> @value

      # first check the parent's type
      if (typeof (@get 'type') is 'object' and (Object.keys (@get 'type')).length > 1)
        # has multiple types (likely union)
        @merge types: [ Type ]
      else
        @set 'type', switch key
          when 'boolean' then key
          else Type

    @extension 'config',    (key, value) -> @set 'config', key is 'true'
    @extension 'mandatory', (key, value) -> @set 'mandatory', key is 'true'
    @extension 'require-instance', (key, value) -> @set 'require-instance', key is 'true'

    @extension 'input',  (key, value) -> @bind 'input',  Forge.Object value
    @extension 'output', (key, value) -> @bind 'output', Forge.Object value

