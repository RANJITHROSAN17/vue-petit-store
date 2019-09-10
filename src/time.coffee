class Tempo
  constructor: (...@args, @callback)->
    @tempo = to_tempo @args[0], "0s", new Date 0

  tick: ->
    tempo = to_tempo ...@args
    return if @tempo.now_idx == tempo.now_idx
    @callback(tempo)
    @tempo = tempo

to_msec = (str)->
  1000 * to_sec str

to_sec = (str)->
  timeout = 0
  str.replace /(\d+)(.)|0/g, (_, num, unit)->
    return null unless num = Number num
    timeout +=
      switch unit
        when "s", "秒"
          num
        when "m", "分"
          60 * num
        when "h", "時"
          3600 * num
        when "d", "日"
          3600 * 24 * num
        when "w", "週"
          3600 * 24 * 7 * num
        when "y", "年"
          3600 * 24 * 365 * num
        else
          throw new Error "#{timestr} at #{num}#{unit}"
  timeout

to_relative_time_distance = (msec)->
  return DISTANCE_NAN if msec < -VALID || VALID < msec || msec - 0 == NaN
  for [limit], idx in DISTANCES when msec < limit
    return DISTANCES[idx]
  return DISTANCE_LONG_AGO

to_tempo = (size, gap_str = "0s", write_at = new Date)->
  size = to_msec size
  gap   = to_msec(gap_str) + timezone
  to_tempo_bare size, gap, write_at - 0

to_tempo_bare = (size, gap, write_at)->
  now_idx = Math.floor(( write_at - gap) / size)
  last_at = (now_idx + 0) * size + gap
  next_at = (now_idx + 1) * size + gap
  remain = next_at - write_at
  since  = write_at - last_at
  timeout = remain

  { last_at, write_at, next_at, timeout, now_idx, timezone, remain, since, gap }

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
  Tempo
  to_msec
  to_sec
  to_tempo
  to_tempo_bare
  to_relative_time_distance
  timezone
}
