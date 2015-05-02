# Yang Compiler

  A YANG compiler which parses YANG text schema into JS class
hierarchy for [node](http://nodejs.org).

  [![NPM Version][npm-image]][npm-url]
  [![NPM Downloads][downloads-image]][downloads-url]

## Installation
```bash
$ npm install yang-compiler
```

## Basic Usage

```coffeescript
compiler = require 'yang-compiler'
schema = """
  module test {
    description 'hello'
  }
  """
module = compiler.compile schema
```

## Literate Coffeescript Documentation

* [Yang Version 1.0 Compiler](src/yang-v1-compiler.litcoffee)
* [Yang Core Compiler](src/yang-core-compiler.litcoffee)

The YANG schema file for generating the v1.0 compiler is [here](./yang-v1-compiler.yang)

## License
  [MIT](LICENSE)

[npm-image]: https://img.shields.io/npm/v/yang-compiler.svg
[npm-url]: https://npmjs.org/package/yang-compiler
[downloads-image]: https://img.shields.io/npm/dm/yang-compiler.svg
[downloads-url]: https://npmjs.org/package/yang-compiler
