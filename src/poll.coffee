Mem = require 'memory-orm'

dexie = null
poll_request = ->
  return unless document?
  Dexie = require("dexie").default
  dexie = new Dexie 'giji'
  dexie
  .version(1).stores
    meta: '&idx'
    data: '&idx'
  poll_request = ->

{ to_tempo } = require "./struct"

is_cache = {}
is_online = is_visible = false



poll = (opt)->
  data: ->
    step: Mem.State.step

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

      list = opt.call @
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
        list = opt.call @
        await Promise.all list.map ([name, id])=>
          @$store.dispatch name, { id, name, @timers }
      else
        for key, val of @timers
          clearTimeout val

poll.cache = (timestr, vuex_id, opt)->
  # console.log { timestr, timeout, url: opt('*') }
  ({ dispatch, state, commit, rootState }, { id, name, timers })->
    url = opt id
    idx = [name, id].join("&")

    roop = ->
      { last_at, write_at, next_at, timeout } = to_tempo timestr


      get_pass = ->
        wait = new Date - write_at
        console.log { timestr, idx, wait, url: null }

      get_by_lf = ->
        { pack } = await dexie.data.get idx
        Mem.State.store pack
        wait = new Date - write_at 
        console.log { timestr, idx, wait, url: '(LF)' }

      get_by_network = ->
        pack = await poll._api[name] url, id
        await dexie.data.put { idx, pack }
        wait = new Date - write_at
        console.log { timestr, idx, wait, url }

      try
        if write_at < is_cache[idx]
          get_pass()
        else
          # IndexedDB metadata not use if memory has past data, 
          unless 0 < is_cache[idx]
            meta = await dexie.meta.get idx

          switch
            when write_at < meta?.next_at
              await get_by_lf()

            when 0 < meta?.next_at
              await get_by_lf()
              await get_by_network()

            else
              await get_by_network()
              dexie.meta.put { idx, next_at }
        is_cache[idx] = next_at
      catch e
        console.error e

      if timeout < 0x7fffffff  #  ほぼ25日
        timers[url] = setTimeout roop, timeout
    roop()

poll.caches = (timestr, opts)->
  for key, cb of opts
    opts[key] = poll.cache timestr, key, cb
  opts

poll._api =
  fetch: (url, cb)->
    res = await fetch url
    data = await res.json()
    Mem.State.transaction ->
      cb data

poll.api = (o)->
  Object.assign poll._api, o

module.exports = { poll }
