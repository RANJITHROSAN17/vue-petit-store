_ = require 'lodash'
{ to_msec, to_tempo_bare, to_relative_time_distance } = require "./time"


class Tempo
  constructor: (...@args, @cb)->
    @tempo = to_tempo @args[0], @args[1] || "0s", new Date 0

  tick: ->
    tempo = to_tempo ...@args
    return if @tempo.now_idx == tempo.now_idx
    @cb tempo
    @tempo = tempo


time_base = (method)-> (id, { times })->
  default_id = "#{id}_default"
  tail_ids = "#{id}_tail_ids"
  tail_funcs = "#{id}_tail_funcs"

  data: ->
    o = {}
    times.forEach (time)=>
      tail_id = "#{id}_#{time}"
      _.set o, tail_id, null
    o

  created: ->
    @[tail_ids] = []
    @[tail_funcs] = []

    id_value = _.get @, id

    times.forEach (time)=>
      msec = to_msec time
      tail_id = "#{id}_#{time}"
      _.set @, tail_id, id_value

      @[tail_ids].push tail_id
      @[tail_funcs].push method (value)=>
        _.set @, tail_id, value
      , msec

    @[default_id] = id_value

  watch:
    [id]: (newValue)->
      for tail_func, idx in @[tail_funcs]
        tail_func newValue

debounces = time_base _.debounce
throttles = time_base _.throttle
delays = time_base (cb, msec)-> (value)->
  setTimeout cb, msec, value


relative = (id, { limit, format } = {})->
  now_id = "#{id}_now"
  msec_id = "#{id}_msec"
  tick_id = "#{id}_tick"
  text_id = "#{id}_text"
  limit_id = "#{id}_limit"
  tempo_id = "#{id}_tempo"
  distance_id = "#{id}_distance"
  interval_id = "#{id}_interval"

  data: ->
    [now_id]: Date.now()
    [limit_id]: to_msec limit

  computed:
    [msec_id]: ->
      @[now_id] - new Date(@[id]).getTime()

    [distance_id]: ->
      to_relative_time_distance @[msec_id]

    [tempo_id]: ->
      [_, interval] = @[distance_id]
      to_tempo_bare interval, 0, @[msec_id]

    [text_id]: ->
      msec = @[msec_id]
      limit_msec = @[limit_id]
      [,,, text] = @[distance_id]
      { now_idx } = @[tempo_id]

      if limit_msec < msec
        clearInterval @[interval_id]
        @[interval_id] = null
        return format @[id]

      @[tick_id]
      if msec < -limit_msec
        return format @[id]
      text.replace '%s', Math.abs now_idx

    [tick_id]: ->
      { timeout } = @[tempo_id]
      if @[interval_id]
        clearInterval @[interval_id]
      @[interval_id] = setInterval =>
        @[now_id] = Date.now()
        @[tick_id]
      , timeout
      return

  beforeDestroy: ->
    clearInterval @[interval_id]
    @[interval_id] = null

module.exports = { relative, delays, debounces, throttles }
