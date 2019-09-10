Mem = require 'memory-orm'

dexie = null
poll_request = ->
  return unless document?
  Dexie = require("dexie/dist/dexie")
  dexie = new Dexie 'poll-web'
  dexie.version(1).stores
    meta: '&idx'
    data: '&idx'

  poll_request = ->

{ to_tempo } = require "./time"

# has_last = {}

is_cache = {}
is_online = is_visible = false



poll = (cb)->
  mounted: ->
    poll_request()
    @timers = {}
    window.addEventListener 'offline', @_waitwake
    window.addEventListener 'online', @_waitwake
    document.addEventListener 'visibilitychange', @_waitwake
    @_waitwake()
      
  destroyed: ->
    window.removeEventListener 'offline', @_waitwake
    window.removeEventListener 'online', @_waitwake
    document.removeEventListener 'visibilitychange', @_waitwake
    for key, val of @timers
      clearTimeout val

  methods:
    get_by_network: ->
      for key, val of @timers
        clearTimeout val

      list = cb.call @
      list.map ([name, id])=>
        idx = [name, id].join("&")
        dexie.meta.delete idx
        dexie.data.delete idx
        is_cache[idx] = 0
      @_waitwake()

    _waitwake: ->
      is_online  = window.navigator.onLine
      is_visible = 'hidden' != document.visibilityState
      is_ok = is_online && is_visible
      if is_ok
        list = cb.call @
        await Promise.all list.map ([name, id])=>
          @$store.dispatch name, { id, name, @timers }
      else
        for key, val of @timers
          clearTimeout val

poll.cache = (timestr = "10s", version = "1.0.0", vuex_id, cb)->
  # console.log { timestr, timeout, url: cb('*') }
  ({ dispatch, state, commit, rootState }, { id, name, timers })->
    url = cb id
    idx = [name, id].join("&")

    roop = ->
      { last_at, write_at, next_at, timeout } = to_tempo timestr

      get_pass = ->
        wait = new Date - write_at
        console.log { timestr, idx, wait, url: null }

      get_by_lf = ->
        meta = await dexie.data.get idx
        Mem.State.store meta

        wait = new Date - write_at 
        console.log { timestr, idx, wait, url: '(LF)' }

      get_by_network = ->
        meta = await poll._api[name] url, id
        meta.idx = idx

        await dexie.data.put meta
        wait = new Date - write_at
        console.log { timestr, idx, wait, url }

      try
        if write_at < is_cache[idx]
          get_pass()
        else
          # IndexedDB metadata not use if memory has past data, 
          unless 0 < is_cache[idx]
            meta = await dexie.meta.get idx
            unless meta?.version == version
              meta = null

          switch
            when write_at < meta?.next_at
              await get_by_lf()

            when 0 < meta?.next_at
              await get_by_lf()
              await get_by_network()

            else
              await get_by_network()
              dexie.meta.put { idx, version, next_at }
        is_cache[idx] = next_at
      catch e
        console.error e

      if timeout < 0x7fffffff  #  ほぼ25日
        timers[url] = setTimeout roop, timeout
    roop()

poll.caches = (...[timestr, version], actions)->
  for key, cb of actions
    actions[key] = poll.cache timestr, version, key, cb
  actions

poll._api =
  fetch: (url, cb)->
    res = await fetch url
    data = await res.json()
    Mem.State.transaction ->
      cb data

poll.api = (o)->
  Object.assign poll._api, o

module.exports = { poll }
