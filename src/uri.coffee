_ = require 'lodash'
{ types, relative_to } = require "./struct"

routeBase = (change_url)-> (id)->
  default_id = "#{id}_default"
  type_id = "#{id}_type"

  created: ->
    @[default_id] = _.get @, id
    @[type_id] = types[@[default_id].constructor]

  mounted: ->
    s = @$route.params[id] || @$route.query[id]
    if s?
      val = @[type_id].by_url s
      _.set @, id, val

  beforeRouteUpdate: (newRoute, oldRoute, next)->
    next()
    s = newRoute.params[id] || newRoute.query[id]
    _.set @, id,
      if s?
        @[type_id].by_url s
      else
        @[default_id]

  watch:
    [id]: ( newVal )->
      { location, href } = @$router.resolve relative_to @$route, { [id]: newVal }, true
      change_url.call @, href

module.exports = m =
  replaceState: routeBase (href)->
    history.replaceState null, null, href

  pushState: routeBase (href)->
    history.pushState null, null, href
