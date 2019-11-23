class Tempo
  constructor: (...@args, @callback)->
    @tempo = to_tempo @args[0], @args[1], new Date 0

  tick: ->
    tempo = to_tempo ...@args
    return if @tempo.now_idx == tempo.now_idx
    @callback(tempo)
    @tempo = tempo

to_msec = (str)->
  1000 * to_sec str

to_sec = (str)->
  timeout = 0
  str.replace /(\d+)([ヵ]?([smhdwy秒分時日週月年])[間]?(半$)?)|0/g, (full, num, fullunit, unit, appendix)->
    return null unless num = Number num
    if '半' == appendix
      num += 0.5
    timeout += num *
      switch unit
        when "s", "秒"
          1
        when "m", "分"
          60
        when "h", "時"
          3600
        when "d", "日"
          3600 * 24
        when "w", "週"
          3600 * 24 * 7
        when "y", "年"
          31556925.147 # 2019 average.
        else
          throw new Error "#{str} at #{num}#{unit}"
  timeout

to_timer = (msec, unit_mode = 1)->
  str = ""
  for o in TIMERS
    unit = o[unit_mode]
    base = o[2]
    if idx = Math.floor( msec / base )
      str += "#{idx}#{unit}"
    msec = msec % base
  str

to_relative_time_distance = (msec)->
  return DISTANCE_NAN if msec < -VALID || VALID < msec || msec - 0 == NaN
  for [limit], idx in DISTANCES when msec < limit
    return DISTANCES[idx]
  return DISTANCE_LONG_AGO

to_tempo = (size, zero_str = "0s", write_at = new Date)->
  size = to_msec size
  zero   = to_msec(zero_str) + tempo_zero
  to_tempo_bare size, zero, write_at - 0, 0

to_tempo_bare = (size, zero, write_at)->
  now_idx = Math.floor(( write_at - zero) / size)
  last_at = (now_idx + 0) * size + zero
  next_at = (now_idx + 1) * size + zero
  remain  =  next_at - write_at
  since   = write_at -  last_at
  timeout = remain

  { last_at, write_at, next_at, timeout, since, remain, zero, now_idx, size }

###
to_tempo_by = (table, zero, write_at)->
  scan_at = write_at - zero
  if scan_at < 0
    now_idx = -1
    next_at = zero
    last_at = -Infinity
  else
    last_at = 0
    for next_at, now_idx in table
      unless scan_at < next_at
        last_at = next_at
        continue
      break

    if last_at == next_at
      next_at = Infinity
    next_at += zero
    last_at += zero

  size   =  next_at -  last_at
  remain =  next_at - write_at
  since  = write_at -  last_at
  timeout = remain

  { last_at, write_at, next_at, timeout, now_idx, remain, since, zero, size, scan_at, table }
###
# バイナリサーチ 高速化はするが、微差なので複雑さのせいで逆に遅いかも？
to_tempo_by = (table, zero, write_at)->
  scan_at = write_at - zero
  if scan_at < 0
    now_idx = -1
    next_at = zero
    last_at = -Infinity
  else
    top_idx = 0
    now_idx = table.length
    while top_idx < now_idx
      mid_idx = (top_idx + now_idx) >>> 1
      next_at = table[mid_idx]
      if next_at <= scan_at
        top_idx = mid_idx + 1
      else
        now_idx = mid_idx

    next_at = table[now_idx] || Infinity
    last_at = table[now_idx - 1] || 0
    next_at += zero
    last_at += zero

  size   =  next_at -  last_at
  remain =  next_at - write_at
  since  = write_at -  last_at
  timeout = remain

  { last_at, write_at, next_at, timeout, now_idx, remain, since, zero, size, table }

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

tempo_zero = (- new Date(0).getDay() ) * DAY + timezone

TIMERS = [
  [ "年", "y", YEAR   ]
  [ "週", "w", WEEK   ]
  [ "日", "d", DAY    ]
  [ "時", "h", HOUR   ]
  [ "分", "m", MINUTE ]
  [ "秒", "s", SECOND ]
]

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
  to_timer
  to_msec
  to_sec
  to_tempo
  to_tempo_bare
  to_tempo_by
  to_relative_time_distance
  timezone
}
