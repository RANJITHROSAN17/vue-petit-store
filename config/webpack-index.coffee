path = require 'path'
webpack = require 'webpack'
merge = require 'webpack-merge'

nodeExternals = require 'webpack-node-externals'
CleanWebpackPlugin = require 'clean-webpack-plugin'

current = process.cwd()

coffee =
  test: /\.coffee$/
  loader: 'coffee-loader'
  options:
    transpile:
      plugins: [
        "@babel/plugin-transform-modules-commonjs"
      ]
      presets: [
        ["env", 
          targets:
            node: "6.11.5"
        ]
      ]

module.exports =
  mode: 'development'
  target: 'node' # Important
  devtool: 'source-map'
  entry:
    "lib/index.min":  './src/index.coffee'
  output:
    path: current
    filename: '[name].js' # Important
    library: 'VuePetitStore'
    libraryTarget: 'umd' # Important

  module:
    rules: [
      coffee
    ]

  resolve:
    extensions: [ '.coffee', '.js' ]

  externals: [nodeExternals()] # Important

  plugins: [
    new CleanWebpackPlugin(['lib'])
  ]
