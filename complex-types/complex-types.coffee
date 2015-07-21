###
YANG comlex-types module

The YANG complex-types module provides additional Yang language
extensions according to [RFC
6095](http://tools.ietf.org/html/rfc6095). These extensions provide
mechanisms to manage the `complex-type` schema definitions which
essentially allows a given YANG data schema module to describe more
than one data models and to build relationships between the data
models.
###

forge = require 'yangforge'

module.exports = forge module,
  before: ->
    @extension 'complex-type',  (key, value) -> @compiler.define 'complext-type', key, value
    @extension 'abstract',      (key, value) -> undefined
    @extension 'extends',       (key, value) -> @merge (@compiler.resolve 'complex-type', key) value
    @extension 'instance-type', (key, value) -> @bind key, (@compiler.resolve 'complex-type', key) value
    @extension 'instance',      (key, value) -> @bind key, forge.Model value
    @extension 'instance-list', (key, value) -> @bind key, forge.Array model: value

###
      @bind key, switch
        when (DS.Meta.instanceof (value.get? 'type')) then DS.BelongsTo.extend value
        else DS.Property.extend value
###
