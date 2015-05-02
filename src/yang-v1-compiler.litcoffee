# Yang Version 1.0 Compiler

The Yang v1 compiler is a Yang schema derived compiler that implements
the [RFC 6020](http://www.rfc-editor.org/rfc/rfc6020.txt) compliant
language extensions.  It is compiled by the `yang-core-compiler` to
produce a new compiler that can then be used to compile any other v1
compatible Yang schema definitions into JS code.

Other uses of this compiler can be to compile yet another compiler
that can extend the Yang v1 extension keywords with other syntax that
can then natively support other Yang schemas without requiring the use
of `prefix` semantics to define the schema definitions deriving from
the extension keywords.

This `compiler` suite was created specifically to allow schema based
augmentation of the base YANG v1.0 language specifications, to
natively extend schema defined extensions for creating more powerful
abstractions on top of the underlying YANG data model schema language.

For an example of interesting ways new YANG compiler can be
extended, take a look at
[storm-compiler](http://github.com/stormstack/storm-compiler).

## Compiling a new Compiler

1. Specify the compiler that will be utilized to compile
2. Configure the compiler with `meta` data context (optional)
3. Compile the target schema with the configured compiler
6. Extend the compiled output with compiler used to compile

We first select the locally available `yang-core-compiler` as the
initial compiler that will be used to generate the new Yang v1.0
Compiler.  Click [here](./yang-core-compiler.litcoffee) to learn more
about the core compiler.

    compiler = (require './yang-core-compiler')

Here we are explicitly loading the [schema](../yang-v1-compiler.yang)
file contents and passing it into the `compiler` for the `compile`
operation.  This is because the `yang-core-compiler` only natively
accepts YANG schema as text string.  We'll be extending this new
`yang-v1-compiler` to allow for more flexible input into the `compile`
routine below.

    path = require 'path'
    file = path.resolve __dirname, '../yang-v1-compiler.yang'
    schema = (require 'fs').readFileSync file, 'utf-8'
    
    module.exports = (compiler.compile schema).configure ->

## Configure the newly compiled yang-v1-compiler module

Since we are generating a new `compiler`, we infuse this module with
`yang-compiler` capabilities.

      @extend compiler

We then **override** the `compile` routine to accept more flexible
input formats such as an Object with schema and directory properties.
This enables the new compiler to directly fetch and read the passed in
file's contents.

      @compile = (source) ->
        compiler.compile.call this, switch
          when typeof source is 'string' then source
          when source instanceof Object
            (require 'fs').readFileSync source.schema, 'utf-8'

The following defines built-in `map` and `importers` for the compiler
to use when it encounters an `import` or `include` statement while
processing the schema being compiled.  The `map` object is used to
resolve the modules being import/include.

      @set map: {}, importers: []

The `register` routine allows definition of additional built-in
importers to enable the new compiler to be able to perform external
module loading capability during `compile` operation.  The `regsiter`
accepts a regex as key and a function to be invoked when a target
module being imported matches the regex.  Every call to `register`
**prepends** to the internal array list of `importers`.

      @register = (regex, func) ->
        ((@get 'importers').unshift regex: regex, f: func ) if regex instanceof RegExp and func instanceof Function

      @resolveFile = (filename) -> switch
        when path.isAbsolute filename then filename
        else path.resolve (path.dirname module.parent?.filename), filename

Here we `register` a couple of `importers` that the `yang-v1-compiler`
will natively support.

      @register /.*\.yang$/, (filename) -> @compile schema: @resolveFile filename
      @register /.*/, (filename) -> require filename

The `import` routine allows a new module to be loaded into the current
compiler's internal metadata.  Since it will be auto-invoked during
the YANG schema `compile` process when it encounters `import/include`
directive, it would not need to be explicitly invoked, but sometimes
it may be convenient to call this directly to bypass using the
`importers` for whatever reason.

      @import = (name) ->
        source = @get "map.#{name}"
        for importer in (@get 'importers') when source?.match? importer.regex
          try
            m = importer.f.call this, source
          catch err
            continue
          @set "module/#{name}", m
          return m
        err ?= "no matching 'source' found in the map"
        console.log "WARN: unable to import module '#{name}' due to #{err}"
        undefined
      
Then we perform various `meta` data operations to alter the behavior
of the `compiler` during `compile` operation.  The primary parameter
for extending the underlying extensions is the `resolver`.

The `resolver` is a JS function which is used by the `compiler` when
defined for a given Yang extension keyword to handle that particular
extension keyword.  It can resolve to a new class definition that will
house the keyword and its sub-statements (for container style
keywords) or perform a specific operation without returning any value
for handling non-data schema extensions such as import, include, etc.

The `resolver` function runs with the context of the `compiler` itself
so that the `this` keyword can be used to access any `meta` data or
other functions available within the `compiler`.
  
Optionally, other parameters can be passed in during `meta` data
augmentation as a collection of key/value pairs which inform what the
valid substatements are for the given extension keyword.  The `key` is
the name of the extension that can be further defined under the given
extension and the `value` specifies the **cardinality** of the given
sub statement (how many times it can appear under the given
statement). This facility is provided here due to the fact that Yang
version 1.0 language definition does not provide a sub-statement
extension to the `extension` keyword to specify such constraints.

Here we associate a new `resolver` to the `augment` statement
extension.  The behavior of `augment` is to expand the target-node
identified by the `argument` with additional sub-statements described
by the `augment` statement.

      @merge 'yang/augment', resolver: (arg, params) -> @[arg]?.extend? params; null

For below `import` and `include` statements, special resolvers are
associated to handle accessing the specified `argument` within the
scope of the current schema being compiled.

      @merge 'yang/import', resolver: (arg, params) ->
        mod = (@get "module/#{arg}") ? @import arg
        params.prefix ?= mod?.prefix
        @set "module/#{params.prefix}", mod
        null

      @merge 'yang/include', resolver: (arg, params) ->
        mod = @get "submodule/#{arg}" ? @import arg
        @extend mod
        null

The `belongs-to` statement is only used in the context of a
`submodule` definition which is processed as a sub-compile stage
within the containing `module` defintion.  Therefore, when this
statement is encountered, it would be processed within the context of
the governing `compile` process which means that the metadata
available within that context will be made *eventually available* to
the included submodule.

      @merge 'yang/belongs-to', resolver: (arg, params) -> @set "module/#{params.prefix}", (@get "module/#{arg}"); null

The `refine` statement uses similar extend capability as `augment`.

      @merge 'yang/refine', resolver: (arg, params) -> @[arg]?.extend? params; null

The `uses` statement references a `grouping` node available within the
context of the schema being compiled to return the contents at the
current `uses` node context.

      @merge 'yang/uses', resolver: (arg, params) -> @get "grouping/#{arg}"

Specify the 'meta' type statements so that they are only added into
the metadata section of the compiled output.

      @merge 'yang/feature',  meta: true
      @merge 'yang/grouping', meta: true
      @merge 'yang/identity', meta: true
      @merge 'yang/revision', meta: true
      @merge 'yang/typedef',  meta: true

Specify the statements that should be added to the configuration
defintions but also added into the metadata section of the compiled
output.

      @merge 'yang/module',       export: true
      @merge 'yang/submodule',    export: true
      @merge 'yang/rpc',          export: true
      @merge 'yang/notification', export: true
      
