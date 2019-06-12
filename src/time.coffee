to_msec = (str)->
  1000 * to_sec str

to_sec = (str)->
  timeout = 0
  str.replace /(\d+)(.)|0/g, (_, num, unit)->
    return null unless num = Number num
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

to_relative_time_distance = (msec)->
  return DISTANCE_NAN if msec < -VALID || VALID < msec || msec - 0 == NaN
  for [limit], idx in DISTANCES when msec < limit
    return DISTANCES[idx]
  return DISTANCE_LONG_AGO

to_tempo = (since, gap = "0s", write_at = new Date)->
  since = to_msec since
  gap   = to_msec gap
  gap  -= timezone
  write_at -= 0
  to_tempo_bare since, gap, write_at

to_tempo_bare = (since, gap, write_at)->
  now_idx = Math.floor(( write_at - gap) / since)
  last_at = (now_idx + 0) * since + gap
  next_at = (now_idx + 1) * since + gap
  timeout = next_at - write_at

  { last_at, write_at, next_at, timeout, now_idx, timezone, since, gap }


SECOND = to_msec  "1s"
MINUTE = to_msec  "1m"
HOUR =   to_msec  "1h"
DAY =    to_msec  "1d"
WEEK =   to_msec  "1w"
INTERVAL = 0x7fffffff # 31bits.
MONTH =  to_msec "30d"
YEAR =   to_msec  "1y"
VALID = 0xfffffffffffff # 52 bits.

TIMEZONE_OFFSET_JP = to_msec "-9h"

timezone =
  if window?
    MINUTE * (new Date).getTimezoneOffset()
  else
    TIMEZONE_OFFSET_JP

DISTANCES = [
  DISTANCE_NAN = 
  [   -VALID, INTERVAL,   YEAR, "？？？"]
  [    -YEAR, INTERVAL,   YEAR, "%s年後"]
  [   -MONTH, INTERVAL,  MONTH, "%sヶ月後"]
  [    -WEEK,     WEEK,   WEEK, "%s週間後"]
  [     -DAY,      DAY,    DAY, "%s日後"]
  [    -HOUR,     HOUR,   HOUR, "%s時間後"]
  [  -MINUTE,   MINUTE, MINUTE, "%s分後"]
  [   -25000,   SECOND, SECOND, "%s秒後"]
  [    25000,    25000,  25000, "今"]
  [   MINUTE,   SECOND, SECOND, "%s秒前"]
  [     HOUR,   MINUTE, MINUTE, "%s分前"]
  [      DAY,     HOUR,   HOUR, "%s時間前"]
  [     WEEK,      DAY,    DAY, "%s日前"]
  [    MONTH,     WEEK,   WEEK, "%s週間前"]
  [     YEAR, INTERVAL,  MONTH, "%sヶ月前"]
  [    VALID, INTERVAL,   YEAR, "%s年前"]
  DISTANCE_LONG_AGO =
  [ Infinity, INTERVAL,  VALID, "昔"]
]

module.exports = m = {
  to_msec
  to_sec
  to_tempo
  to_tempo_bare
  to_relative_time_distance
  timezone

  msec_in_day: ( at )->
    return null unless at?
    return (at - timezone) % DAY
}
