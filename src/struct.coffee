_ = require 'lodash'

relative_to = ({ name, params, query, hash }, o, is_replace)->
  unless is_replace
    params = _.cloneDeep params
    query  = _.cloneDeep query
  to = { name, params, query, hash }
  for key, val of o
    if params[key]
      params[key] = val
    else
      query[key] = val
  to

to_x = (type, sp, nil)-> (u)->
  switch u?.constructor
    when null, undefined, sp
      nil
    when type
      u
    else
      type u

to_msec = (str)->
  1000 * to_sec str

to_sec = (str)->
  timeout = 0
  str.replace /(\d+)(.)|0/g, (_, num, unit)->
    return unless num = Number num
    timeout +=
      switch unit
        when "s"
          num
        when "m"
          60 * num
        when "h"
          3600 * num
        when "d"
          3600 * 24 * num
        when "w"
          3600 * 24 * 7 * num
        when "y"
          3600 * 24 * 365 * num
        else
          throw new Error "#{timestr} at #{num}#{unit}"
  timeout

to_tempo = (since, gap = "0s")->
  since = to_msec since
  gap   = to_msec gap
  gap  -= nine_hour

  write_at = new Date - 0

  now_idx = parseInt(( write_at - gap) / since)
  last_at = (now_idx + 0) * since + gap
  next_at = (now_idx + 1) * since + gap
  timeout = next_at - write_at

  { last_at, write_at, next_at, timeout, now_idx, timezone, since, gap }

module.exports = {
  relative_to
  to_sec
  to_msec
  to_tempo
  types:
    [Number]:
      to_str: to_x String, NaN, ""
      by_str: to_x Number, "", NaN
      by_url: to_x Number, "", NaN
    [String]:
      to_str: to_x String, null, ""
      by_str: to_x String, "", null
      by_url: to_x String, "", null
    [Array]:
      to_str: JSON.stringify
      by_str: JSON.parse
      by_url: to_x Array, null, null
    [Object]:
      to_str: JSON.stringify
      by_str: JSON.parse
}

nine_hour = to_msec '9hour'
timezone = -nine_hour
