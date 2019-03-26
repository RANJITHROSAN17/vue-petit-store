_ = require 'lodash'

module.exports = m =
  vuex_read: (key, opt)->
    dir = (opt.on || "").split('.')
    getter = [...dir[0..-1], key].join('.')

    computed:
      [key]:
        get: ->
          _.get @$store.state, getter

  vuex: (key, opt)->
    dir = (opt.on || "").split('.')
    mutation = [dir[0], 'update'].join('/')
    getter = [...dir[0..-1], key].join('.')
    setter = [...dir[1..-1], key].join('.')
  
    computed:
      [key]:
        get: ->
          _.get @$store.state, getter
        set: (val)->
          o = _.set {}, setter, val
          @$store.commit mutation, o

