_ = require 'lodash'
Cookie = require 'tiny-cookie'
{ types, relative_to } = require "./struct"

try
  test = '__vue-localstorage-test__'

  Cookie.set test, test, expres: '1M'
  Cookie.remove test

  window.localStorage.setItem test, test
  window.localStorage.removeItem test

  window.sessionStorage.setItem test, test
  window.sessionStorage.removeItem test

  history || throw new Error "can't use history API."
catch e
  console.warn 'Local storage not supported by this browser'


baseState = (change_url)-> (id)->
  default_id = "#{id}_default"
  type_id = "#{id}_type"

  created: ->
    @[default_id] = _.get @, id
    @[type_id] = types[@[default_id].constructor]

  mounted: ->
    newVal = @$route.params[id] || @$route.query[id]
    if newVal?
      @[id] = @[type_id].by_url newVal

  beforeRouteUpdate: (newRoute, oldRoute, next)->
    next()
    newVal = newRoute.params[id] || newRoute.query[id]
    if newVal?
      @[id] = @[type_id].by_url newVal

  watch:
    [id]: ( newVal )->
      { location, href } = @$router.resolve relative_to @$route, { [id]: newVal }, true
      change_url href

module.exports = m =
  replaceState: baseState (href)->
    history.replaceState null, null, href

  pushState: baseState (href)->
    history.pushState null, null, href
