path = require 'path'
webpack = require 'webpack'
merge = require 'webpack-merge'

nodeExternals = require 'webpack-node-externals'
CleanWebpackPlugin = require 'clean-webpack-plugin'

current = process.cwd()

coffee =
  test: /\.coffee$/
  use: ['babel-loader', 'coffee-loader']

module.exports =
  mode: 'production'
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
