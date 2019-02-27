_ = require 'lodash'
{ Query } = require 'memory-orm'

idx_with_maker = (o, ary_id, name, idx)->
  o["#{name}_id"] = ->
    @[ary_id]?[0..idx].join("-")


module.exports = m =
  path_by: (idx = 'idx', keys)->
    idx_a = "#{idx}_a"
    computed = {}
    computed[idx_a] =
        get: ->
          @[idx].split("-")

    keys.forEach (name, at)->
      return unless name
      key  = "#{name}_id"
      list = "#{name}s"
      computed[key] =
        get: ->
          if at < @[idx_a].length
            @[idx_a][0..at].join("-")
      computed[name] =
        get: ->
          Query[list].find @[key]
    { computed }
  
  vuex_read: (path, keys)->
    dir = path.split('.')
    computed = {}
    keys.map (key)->
      getter = [...dir[0..-1], key].join('.')
      computed[key] =
        get: ->
          _.get @$store.state, getter
    { computed }

  vuex: (path, keys)->
    dir = path.split('.')
    computed = {}
    keys.forEach (key)->
      mutation = "#{dir[0]}/update"
      getter = [...dir[0..-1], key].join('.')
      setter = [...dir[1..-1], key].join('.')
      computed[key] =
        get: ->
          _.get @$store.state, getter
        set: (val)->
          o = _.set {}, setter, val
          @$store.commit mutation, o
    { computed }

