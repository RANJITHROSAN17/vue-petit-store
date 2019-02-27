{ Query } = require 'memory-orm'

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
