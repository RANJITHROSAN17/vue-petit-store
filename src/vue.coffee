_ = require 'lodash'

$shared_memory = {}

module.exports = m =
  share: (id)->
    $shared_memory[id] ?= null

    data: ->
      { $shared_memory }
    computed:
      [id]:
        get: ->
          $shared_memory[id]
        set: (o)->
          $shared_memory[id] = o

  vuex_read: (id, opt)->
    dir = (opt.on || "").split('.')
    getter = [...dir[0..-1], id].join('.')

    computed:
      [id]:
        get: ->
          _.get @$store.state, getter

  vuex: (id, opt)->
    dir = (opt.on || "").split('.')
    mutation = [dir[0], 'update'].join('/')
    getter = [...dir[0..-1], id].join('.')
    setter = [...dir[1..-1], id].join('.')
  
    computed:
      [id]:
        get: ->
          _.get @$store.state, getter
        set: (val)->
          o = _.set {}, setter, val
          @$store.commit mutation, o

