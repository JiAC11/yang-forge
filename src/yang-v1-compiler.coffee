###*
# default keywords supported are to allow definition of the YANG
# language using the 'extension' keyword
#
# extension (standard)
# argument (standard)
#
# constructor (non-standard)
# substatements (non-standard)
###

schema =
  'module yang-v1-compiler':
    'extension anyxml': undefined
    'extension augment':
      argument: 'target-node'
      resolver: (arg, params) -> @[arg]?.extend? params; null
    'extension base': argument: 'name'
    'extension belongs-to': argument: 'module'
    'extension bit':
      argument: 'name'
      'sub description': value: '0..1'
      'sub reference': value: '0..1'
      'sub status': value: '0..1'
      'sub position': value: '0..1'
    'extension case': argument: 'name'
    'extension choice': undefined
    'extension config': argument: 'value'
    'extension contact': 'argument text': 'yin-element': true
    'extension container':
      argument: 'name'
      'sub anyxml': value: '0..n'
      'sub choice': value: '0..n'
      'sub config': value: '0..1'
      'sub container': value: '0..n'
      'sub description': value: '0..1'
      'sub grouping': value: '0..n'
      'sub if-feature': value: '0..n'
      'sub leaf': value: '0..n'
      'sub leaf-list': value: '0..n'
      'sub list': value: '0..n'
      'sub must': value: '0..n'
      'sub presence': value: '0..1'
      'sub reference': value: '0..1'
      'sub status': value: '0..1'
      'sub typedef': value: '0..n'
      'sub uses': value: '0..n'
      'sub when': value: '0..1'
    'extension default': argument: 'value'
    'extension description': 'argument text': 'yin-element': true
    'extension deviate': argument: 'value'
    'extension deviation': undefined
    'extension enum':
      argument: 'name'
      'sub description': value: '0..1'
      'sub reference': value: '0..1'
      'sub status': value: '0..1'
      'sub value': value: '0..1'
    'extension error-app-tag': argument: 'value'
    'extension error-message': 'argument value': 'yin-element': true
    'extension feature':
      argument: 'name'
      'sub description': value: '0..1'
      'sub if-feature': value: '0..n'
      'sub reference': value: '0..1'
      'sub status': value: '0..1'
    'extension fraction-digits': argument: 'value'
    'extension grouping':
      argument: 'name'
      'sub anyxml': value: '0..n'
      'sub choice': value: '0..n'
      'sub container': value: '0..n'
      'sub description': value: '0..1'
      'sub grouping': value: '0..n'
      'sub leaf': value: '0..n'
      'sub leaf-list': value: '0..n'
      'sub list': value: '0..n'
      'sub reference': value: '0..1'
      'sub status': value: '0..1'
      'sub typedef': value: '0..n'
      'sub uses': value: '0..n'
    'extension identity':
      argument: 'name'
      'sub base': value: '0..1'
      'sub description': value: '0..1'
      'sub reference': value: '0..1'
      'sub status': value: '0..1'
    'extension if-feature': argument: 'name'
    'extension import':
      argument: 'module'
      resolver: (arg, params) -> @set params.prefix, (@get "module:#{arg}"); null
      'sub prefix': value: '0..1'
      'sub revision-date': value: '0..1'
    'extension include':
      argument: 'module'
      resolver: (arg, params) -> @extend (@get "module:#{arg}"); null
      'sub revision-date': value: '0..1'
    'extension input':
      'sub anyxml': value: '0..n'
      'sub choice': value: '0..n'
      'sub container': value: '0..n'
      'sub grouping': value: '0..n'
      'sub leaf': value: '0..n'
      'sub leaf-list': value: '0..n'
      'sub list': value: '0..n'
      'sub typedef': value: '0..n'
      'sub uses': value: '0..n'
    'extension key': argument: 'value'
    'extension leaf':
      argument: 'name'
      'sub config': value: '0..1'
      'sub default': value: '0..1'
      'sub description': value: '0..1'
      'sub if-feature': value: '0..n'
      'sub mandatory': value: '0..1'
      'sub must': value: '0..n'
      'sub reference': value: '0..1'
      'sub status': value: '0..1'
      'sub type': value: '0..1'
      'sub units': value: '0..1'
      'sub when': value: '0..1'
    'extension leaf-list':
      argument: 'name'
      'sub config':  value: '0..1'
      'sub description':  value: '0..1'
      'sub if-feature': value: '0..n'
      'sub max-elements': value: '0..1'
      'sub min-elements': value: '0..1'
      'sub must': value: '0..n'
      'sub ordered-by': value: '0..1'
      'sub reference': value: '0..1'
      'sub status': value: '0..1'
      'sub type': value: '0..1'
      'sub units': value: '0..1'
      'sub when': value: '0..1'
    'extension length': argument: 'value'
    'extension list':
      argument: 'name'
      'sub anyxml': value: '0..n'
      'sub choice': value: '0..n'
      'sub config': value: '0..1'
      'sub container': value: '0..n'
      'sub description': value: '0..1'
      'sub grouping': value: '0..n'
      'sub if-feature': value: '0..n'
      'sub key': value: '0..1'
      'sub leaf': value: '0..n'
      'sub leaf-list': value: '0..n'
      'sub list': value: '0..n'
      'sub max-elements': value: '0..1'
      'sub min-elements': value: '0..1'
      'sub must': value: '0..n'
      'sub ordered-by': value: '0..1'
      'sub reference': value: '0..1'
      'sub status': value: '0..1'
      'sub typedef': value: '0..n'
      'sub unique': value: '0..1'
      'sub uses': value: '0..n'
      'sub when': value: '0..1'
    'extension mandatory': argument: 'value'
    'extension max-elements': argument: 'value'
    'extension min-elements': argument: 'value'
    'extension module':
      argument: 'name'
      'sub anyxml': value: '0..n'
      'sub augment': value: '0..n'
      'sub choice': value: '0..n'
      'sub contact': value: '0..1'
      'sub container': value: '0..n'
      'sub description': value: '0..1'
      'sub deviation': value: '0..n'
      'sub extension': value: '0..n'
      'sub feature': value: '0..n'
      'sub grouping': value: '0..n'
      'sub identity': value: '0..n'
      'sub import': value: '0..n'
      'sub include': value: '0..n'
      'sub leaf': value: '0..n'
      'sub leaf-list': value: '0..n'
      'sub list': value: '0..n'
      'sub namespace': value: '0..1'
      'sub notification': value: '0..n'
      'sub organization': value: '0..1'
      'sub prefix': value: '0..1'
      'sub reference': value: '0..1'
      'sub revision': value: '0..n'
      'sub rpc': value: '0..n'
      'sub typedef': value: '0..n'
      'sub uses': value: '0..n'
      'sub yang-version': value: '0..1'
    'extension must':
      argument: 'condition'
      'sub description': value: '0..1'
      'sub error-app-tag': value: '0..1'
      'sub error-message': value: '0..1'
      'sub reference': value: '0..1'
    'extension namespace': argument: 'uri'
    'extension notification': undefined # not yet supported! (7.14.1)
    'extension ordered-by': argument: 'value'
    'extension organization': 'argument text': 'yin-element': true
    'extension output':
      'sub anyxml': value: '0..n'
      'sub choice': value: '0..n'
      'sub container': value: '0..n'
      'sub grouping': value: '0..n'
      'sub leaf': value: '0..n'
      'sub leaf-list': value: '0..n'
      'sub list': value: '0..n'
      'sub typedef': value: '0..n'
      'sub uses': value: '0..n'
    'extension path': argument: 'value'
    'extension pattern': argument: 'value'
    'extension position': argument: 'value'
    'extension prefix': argument: 'value'
    'extension presence': argument: 'value'
    'extension range': argument: 'value'
    'extension reference': 'argument text': 'yin-element': true
    'extension refine':
      argument: 'target-node'
      resolver: (arg, params) -> @[arg]?.extend? params; null # XXX - need to handle different?
    'extension require-instance': argument: 'value'
    'extension revision':
      argument: 'date'
      'sub description': value: '0..1'
      'sub reference': value: '0..1'
    'extension revision-date': argument: 'date'
    'extension rpc':
      argument: 'name'
      'sub description': value: '0..1'
      'sub grouping': value: '0..n'
      'sub if-feature': value: '0..n'
      'sub input': value: '0..1'
      'sub output':  value: '0..1'
      'sub reference':  value: '0..1'
      'sub status':  value: '0..1'
      'sub typedef': value: '0..n'
    'extension status': argument: 'value' # current/deprecated/obsolete
    'extension submodule':
      argument: 'name'
      'sub anyxml': value: '0..n'
      'sub augment': value: '0..n'
      'sub belongs-to': value: '0..1'
      'sub choice': value: '0..n'
      'sub contact': value: '0..1'
      'sub container': value: '0..n'
      'sub description': value: '0..1'
      'sub deviation': value: '0..n'
      'sub extension': value: '0..n'
      'sub feature': value: '0..n'
      'sub grouping': value: '0..n'
      'sub identity': value: '0..n'
      'sub import': value: '0..n'
      'sub include': value: '0..n'
      'sub leaf': value: '0..n'
      'sub leaf-list': value: '0..n'
      'sub list': value: '0..n'
      'sub namespace': value: '0..1'
      'sub notification': value: '0..n'
      'sub organization': value: '0..1'
      'sub prefix': value: '0..1'
      'sub reference': value: '0..1'
      'sub revision': value: '0..n'
      'sub rpc': value: '0..n'
      'sub typedef': value: '0..n'
      'sub uses': value: '0..n'
      'sub yang-version': value: '0..1'
    'extension type':
      argument: 'name'
      'sub bit': value: '0..n'
      'sub enum': value: '0..n'
      'sub length': value: '0..1'
      'sub path': value: '0..1'
      'sub pattern': value: '0..1'
      'sub range': value: '0..1'
      'sub require-instance': value: '0..1'
      'sub type': value: '0..n'
    'extension typedef':
      argument: 'name'
      'sub default': value: '0..1'
      'sub description': value: '0..1'
      'sub units': value: '0..1'
      'sub type': value: '0..1'
      'sub reference': value: '0..1'
    'extension unique': argument: 'tag'
    'extension uses':
      argument: 'name'
      resolver: (arg, params) -> (@get "grouping:#{arg}")
      'sub augment': value: '0..1'
      'sub description': value: '0..1'
      'sub if-feature': value: '0..n'
      'sub refine': value: '0..1'
      'sub reference': value: '0..1'
      'sub status': value: '0..1'
      'sub when': value: '0..1'
    'extension value': argument: 'value'
    'extension when': argument: 'condition'

    ###*
    # schema for this module
    ###
    'revision 2015-02-19':
      description: "Initial revision"
      reference: "RFC-6020"

    'yang-version': '1.0'

module.exports = (require './yang-core-compiler').compile schema, compiler: true
