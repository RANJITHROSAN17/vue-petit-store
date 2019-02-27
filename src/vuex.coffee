_ = require 'lodash'

module.exports = m =
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

