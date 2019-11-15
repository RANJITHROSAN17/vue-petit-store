
{
  timezone
  to_timer
  to_msec
  to_sec
  to_tempo_by
  to_tempo_bare
} = require "./time"
_ = require "lodash"

reg_parse = /(\d+)年(\d+)月(\d+)日\(([^)])\)(\d+)時(\d+)分(\d+)秒/
reg_token = /[yYQqMLwIdDecihHKkms]o|(\w)\1*|''|'(''|[^'])+('|$)|./g

calc_set = (path, o)->
  for key, val of o
    @calc[path][key] = val[path] || val

sub_define = (msec, size)->
  range = [size]
  msec_min = msec_max = msec = msec / size
  { range, msec, msec_min, msec_max }

daily_define = (msec, day)->
  range = [Math.floor(msec / day)]
  msec = msec_min = msec_max = range[0] * day
  { range, msec, msec_min, msec_max }

daily_measure = (msec, day)->
  range = [Math.floor(msec / day), Math.ceil(msec / day)]
  msec_min = range[0] * day
  msec_max = range[1] * day
  { range, msec, msec_min, msec_max }

export class FictionalDate
  constructor: ->
    @dic = {}
    @calc =
      divs: {}
      idx:  {}
      gap:  {}
      zero: {}
      msec: {}
      range: {}
      msec_min: {}
      msec_max: {}

  planet: (revolution = g.calc.msec.year, synodic = g.moon.msec, rotation = g.calc.msec.day, axtial_tilt = g.dic.axtial_tilt, geo = g.dic.geo)->
    year = daily_measure revolution, rotation
    moon = daily_measure    synodic, rotation
    day  = daily_define    rotation, rotation
    calc_set.call @, "range",    { year, moon, day }
    calc_set.call @, "msec",     { year, moon, day }
    calc_set.call @, "msec_min", { year, moon, day }
    calc_set.call @, "msec_max", { year, moon, day }

    [lat, lng] = geo
    tz_offset = rotation / 360 * lng

    Object.assign @dic, { geo, lat, lng, axtial_tilt, tz_offset }
    @

  yeary: ( weeks = g.dic.weeks, months = g.dic.months, month_ranges )->
    month = daily_measure @calc.msec.year / months.length, @calc.msec.day
    week  = daily_define  weeks.length * @calc.msec.day,   @calc.msec.day
    calc_set.call @, "range",    { month, week }
    calc_set.call @, "msec",     { month, week }
    calc_set.call @, "msec_min", { month, week }
    calc_set.call @, "msec_max", { month, week }

    unless month_ranges
      month_ranges =
        for str, idx in months
          @calc.range.month[1 - idx % 2]
    month_ranges[1] = 0
    month_sum = 0
    for range in month_ranges
      month_sum += range

    Object.assign @dic, { weeks, months, month_ranges, month_sum }
    @

  moony: (moons)->
    Object.assign @dic, { moons }
    @

  daily: (hours = g.dic.hours, minutes = g.dic.minutes, seconds = g.dic.seconds)->
    hour   = sub_define    @calc.msec.day,    hours.length
    minute = sub_define        hour.msec,  minutes.length
    second = sub_define      minute.msec,  seconds.length
    calc_set.call @, "range",    { hour, minute, second }
    calc_set.call @, "msec",     { hour, minute, second }
    calc_set.call @, "msec_min", { hour, minute, second }
    calc_set.call @, "msec_max", { hour, minute, second }
    Object.assign @dic, { hours, minutes, seconds }
    @

  calendar: (era = g.dic.era, leaps = g.dic.leaps, start = g.dic.start, start_at = g.dic.start_at, moon_idx = g.dic.moon_idx)->
    Object.assign @dic, { era, leaps, start, start_at, moon_idx }
    @

  init: ->
    @def_table()
    @def_calc()
    @def_zero()
    @

  def_table: ->
    day = @calc.msec.day
    [...leaps, period] = @dic.leaps

    @table =
      range:
        year:
          for idx in [0...period]
            is_leap = 0
            for div, mode in leaps
              continue if idx % div
              is_leap = ! mode % 2
            @calc.range.year[is_leap]
    @table.range.year[0] = @calc.range.year[1]
    years = _.uniq @table.range.year

    @table.range.month = month = {}
    for size in years
      a = Array.from @dic.month_ranges
      a[1] = size - @dic.month_sum
      month[size] = a

    upto = (src)->
      msec = 0
      for range in src
        msec += range * day

    year = upto @table.range.year
    period = year[year.length - 1]
    period = daily_define period, day
    calc_set.call @, "msec",     { period }
    calc_set.call @, "msec_min", { period }
    calc_set.call @, "msec_max", { period }

    month = {}
    for size in years
      month[size * day] = upto @table.range.month[size]

    @table.msec = { year, month }

  def_calc: ->
    [..., full_period] = @dic.leaps

    period = full_period
    year   = @dic.months.length
    month  = Math.max ...@calc.range.month
    day    = @dic.hours.length
    hour   = @dic.minutes.length
    minute = @dic.seconds.length
    second = @calc.msec.second
    moon   = Math.min ...@calc.range.moon
    week   = @dic.weeks.length
    calc_set.call @, "divs", { period, year, month, moon, week, day, hour, minute, second }

    [,year, month, day, week, hour, minute, second] = @dic.start.match reg_parse

    year   = year   - 0
    period = Math.floor year / @calc.divs.period
    year   = year % @calc.divs.period

    month  = month  - 0
    day    = day    - 0
    hour   = hour   - 0
    minute = minute - 0
    second = second - 0
    moon   = @dic.moon_idx
    week   = @dic.weeks.indexOf week
    calc_set.call @, "idx", { period, year, month, moon, week, day, hour, minute, second }

  def_zero: ->
    zero_size = (path, idx = 0)=>
      0 - (@calc.idx[path] - idx) * @calc.msec[path]
    zero   = 0 # - @dic.tz_offset
    second = zero   + zero_size "second"
    minute = second + zero_size "minute"
    hour   = minute + zero_size "hour"
    day    = hour   + zero_size "day", 1

    yeary   = @calc.msec.day * @table.range.year[ @calc.idx.year %% @calc.divs.period ]

    month  = day   - @table.msec.month[yeary][ @calc.idx.month - 2 ] || 0
    year   = month - @table.msec.year[         @calc.idx.year  - 1 ] || 0
    period = year  + zero_size "period"

    week   = day   + zero_size("week") / @calc.divs.week
    moon   = day   + zero_size "moon"

    calc_set.call @, "zero", { period, week,   month, day, hour, minute, second }

  slice: (now)->
    period = ([zero, b_size], path)=>
      { last_at, now_idx, size } = o =
        switch path
          when 'year'
            table = @table.msec.year
            to_tempo_by table, zero, now
          when 'month'
            table = @table.msec.month[b_size]
            to_tempo_by table, zero, now
          else
            b_size = @calc.msec[path]
            to_tempo_bare b_size, zero, now
      [last_at, size, now_idx]

    # period in epoch
    p = period [@calc.zero.period], "period"
    w = period [@calc.zero.week  ], "week"
    console.warn w, @calc.zero
    # year   in period
    y = period p, "year"
    # month  in year
    M = period y, "month"
    # day    in month
    d = period M, "day"

    #        in year appendix
    D = period y, "day"
    n = period y, "moon"

    # day    in week (曜日)
    e = period w, "day"

    # hour   in day
    H = period d, "hour"
    # minute in day
    m = period H, "minute"
    s = period m, "second"

    S = [ null, null, now - s[0]]
    G = [ null, null, ( now < @calc.zero.period ) - 0 ]
    G[2] = @dic.era[ G[2] ]
    p[2] = p[2] * @calc.divs.period
    y[2] = y[2] + p[2] + "年"
    M[2] = @dic.months[ M[2] ]
    d[2] = d[2] + 1 + "日"
    H[2] = @dic.hours[ H[2] ]
    m[2] = @dic.minutes[ m[2] ]
    s[2] = @dic.seconds[ s[2] ]

    e[2] = @dic.weeks[ e[2] ]
    { G, p, y,M,d, D,w,e, H,m,s,S }
  
  format: (now, str = "GGyyyyMMdd(eee)HH", { locale } = {})->
    o = @slice now
    str
    .match reg_token
    .map (token)->
      if val = o[token[0]]
        val[2]
      else
        token
    .join("")


# 舞台にする惑星の、自転周期、公転周期、見かけ最大の衛星の軌道周期。
# 暦法利用都市から見て、恒星の南中高度、指で数える最大数、可測惑星数、起算時刻。
# 閏日処理法、閏週処理法、閏月処理法、あたりを変数に

FictionalDate.Gregorian = g = new FictionalDate()
  .planet(
    to_msec('1y')
    2551442881
    to_msec('1d')
    23.4
    [ 35, 135 ]
  )
  .calendar(
    ["西暦", "紀元前"]
    [4, 100, 400]
    "1970年1月1日(木)0時0分0秒"
    0
    27
  )
  .yeary(
    ['月', '火', '水', '木', '金', '土', '日']
    ['睦月','如月','弥生','卯月','皐月','水無月','文月','葉月','長月','神無月','霜月','師走']
    [  31 ,   0 ,  31 ,  30 ,  31 ,   30 ,  31 ,  31 ,  30 ,    31 ,  30 ,  31 ]
  )
  .moony(
    ['朔'   ,'既朔'  ,'三日月','上弦'  ,'上弦','上弦','上弦','上弦','上弦','上弦','上弦','上弦','十三夜','小望月','満月',
     '十六夜','立待月','居待月','臥待月','更待月','下限','下限','下限','下限','下限','下限','下限','下限','晦'    ,'晦'  ]
  )
  .daily(
    [0...24].map (i)-> "#{i}時"
    [0...60].map (i)-> "#{i}分"
    [0...60].map (i)-> "#{i}秒"
  )
  .init()