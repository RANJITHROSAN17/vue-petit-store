_ = require 'lodash'
{ types, relative_to } = require "./struct"

routeBase = (change_url)-> (id)->
  default_id = "#{id}_default"
  type_id = "#{id}_type"

  route_into = (newRoute, oldRoute)->
    s = newRoute.params[id] || newRoute.query[id]
    _.set @, id,
      if s?
        @[type_id].by_url s
      else
        @[default_id]


  created: ->
    @[default_id] = _.get @, id
    @[type_id] = types[@[default_id].constructor]

  # for changed component.
  mounted: ->
    s = @$route.params[id] || @$route.query[id]
    if s?
      val = @[type_id].by_url s
      _.set @, id, val

  # for same component but uri changed.
  beforeRouteEnter: (newRoute, oldRoute, next)->
    next (vm)->
      route_into.call vm, newRoute, oldRoute

  # for same component but uri changed.
  beforeRouteUpdate: (newRoute, oldRoute, next)->
    next()
    route_into.call @, newRoute, oldRoute

  watch:
    [id]: ( newVal )->
      { location, href } = @$router.resolve relative_to @$route, { [id]: newVal }, true
      change_url.call @, href

module.exports = m =
  replaceState: routeBase (href)->
    history.replaceState null, null, href

  pushState: routeBase (href)->
    history.pushState null, null, href
