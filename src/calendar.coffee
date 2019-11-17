
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
default_parse_format  = "yyyyMMdd"
default_format_format = "GGyyyyMMdd(eee)HHmmss"

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
  constructor: (o)->
    if o
      { dic, calc } = o
      @dic  = _.cloneDeep dic
      @calc = _.cloneDeep calc
    else
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

  dup: ->
    new @constructor @

  planet: (
    revolution = g.calc.msec.year,
    synodic    = g.calc.msec.moon,
    rotation   = g.calc.msec.day, 
    ecliptic_zero = g.dic.ecliptic_zero,
    axtial_tilt   = g.dic.axtial_tilt,
    geo = g.dic.geo
  )->
    year   = daily_measure revolution, rotation
    moon   = daily_measure    synodic, rotation
    day    = daily_define    rotation, rotation
    calc_set.call @, "range",    { year, moon, day }
    calc_set.call @, "msec",     { year, moon, day }
    calc_set.call @, "msec_min", { year, moon, day }
    calc_set.call @, "msec_max", { year, moon, day }

    [lat, lng] = geo
    tz_offset = rotation / 360 * lng

    Object.assign @dic, { geo, lat, lng, axtial_tilt, ecliptic_zero, tz_offset }
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

  seasonly: (seasons)->
    season = sub_define @calc.msec.year, seasons.length
    calc_set.call @, "range",    { season }
    calc_set.call @, "msec",     { season }
    calc_set.call @, "msec_min", { season }
    calc_set.call @, "msec_max", { season }
    Object.assign @dic, { seasons }
    @

  daily: (hours = g.dic.hours, minutes = g.dic.minutes)->
    hour   = sub_define @calc.msec.day,  hours.length
    minute = sub_define      hour.msec,  minutes.length
    second = sub_define    minute.msec,  minute.msec / 1000
    calc_set.call @, "range",    { hour, minute, second }
    calc_set.call @, "msec",     { hour, minute, second }
    calc_set.call @, "msec_min", { hour, minute, second }
    calc_set.call @, "msec_max", { hour, minute, second }
    Object.assign @dic, { hours, minutes }
    @

  calendar: (era = g.dic.era, start = g.dic.start, start_at = g.dic.start_at, leaps = g.dic.leaps, moon_idx = g.dic.moon_idx)->
    Object.assign @dic, { era, leaps, start, start_at, moon_idx }
    @

  init: ->
    @table = @def_table()
    calc_set.call @, "idx",  @def_calc()
    calc_set.call @, "zero", @def_zero()
    @

  def_table: ->
    day = @calc.msec.day
    [...leaps, period] = @dic.leaps

    range =
      year:
        for idx in [0...period]
          is_leap = 0
          for div, mode in leaps
            continue if idx % div
            is_leap = ! mode % 2
          @calc.range.year[is_leap]
    range.year[0] = @calc.range.year[1]
    years = _.uniq range.year

    range.month = month = {}
    for size in years
      a = Array.from @dic.month_ranges
      a[1] = size - @dic.month_sum
      month[size] = a

    upto = (src)->
      msec = 0
      for i in src
        msec += i * day

    year = upto range.year
    period = year[year.length - 1]
    period = daily_define period, day
    calc_set.call @, "msec",     { period }
    calc_set.call @, "msec_min", { period }
    calc_set.call @, "msec_max", { period }

    month = {}
    for size in years
      month[size * day] = upto range.month[size]

    { range, msec: { year, month } }

  def_calc: ->
    [..., full_period] = @dic.leaps

    period = full_period
    year   = @dic.months.length
    month  = Math.max ...@calc.range.month
    day    = @dic.hours.length
    hour   = @dic.minutes.length
    minute = @calc.msec.minute / @calc.msec.second
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
    { period, year, month, moon, week, day, hour, minute, second }

  def_zero: ->
    zero_size = (path, idx = 0)=>
      0 - (@calc.idx[path] - idx) * @calc.msec[path]
    zero   = 0
    second = zero   + zero_size "second"
    minute = second + zero_size "minute"
    hour   = minute + zero_size "hour"
    day    = hour   + zero_size "day", 1

    yeary   = @calc.msec.day * @table.range.year[ @calc.idx.year %% @calc.divs.period ]

    month  = day   - @table.msec.month[yeary][ @calc.idx.month - 2 ] || 0
    year   = month - @table.msec.year[         @calc.idx.year  - 1 ] || 0
    period = year  + zero_size "period"

    week   = day   + zero_size("week") / @calc.divs.week

    # 単純のため平気法。春分点から立春点を求める。
    season_idx  = @dic.seasons.indexOf '春分'
    season_zero = @calc.msec.year * season_idx / @dic.seasons.length
    { since } = o = to_tempo_bare @calc.msec.year, year, @dic.ecliptic_zero - season_zero
    season = since
    moon   = day   + zero_size "moon"

    { period, week, season }

  slice: (now)->
    now = now + @dic.tz_offset - @dic.start_at
    period = ([zero, b_size], path)=>
      table = 
        switch path
          when 'year'
            @table.msec.year
          when 'month'
            @table.msec.month[b_size]
          else
            null
      { last_at, now_idx, size } = o =
        if table
          to_tempo_by table, zero, now
        else
          b_size = @calc.msec[path]
          to_tempo_bare b_size, zero, now
      [last_at, size, now_idx]

    # period in epoch
    p  = period [@calc.zero.period], "period"
    w  = period [@calc.zero.week  ], "week"

    # year   in period
    y = period p, "year"
    # month  in year
    M = period y, "month"
    # day    in month
    d = period M, "day"

    #        in year appendix
    D = period y, "day"
    n = period y, "moon"

    # season in year_of_planet
    { last_at, size, now_idx } = to_tempo_bare @calc.msec.year, @calc.zero.season, now 
    Zy = [ last_at, size, now_idx ]
    Z = period Zy, "season"

    # day    in week (曜日)
    e = period w, "day"

    # hour   in day
    H = period d, "hour"
    # minute in day
    m = period H, "minute"
    s = period m, "second"

    y[2] = y[2] + p[2] * @calc.divs.period
    y[2] =
      if 0 < y[2]
        G = [ null, null, 0 ]
        y[2] + "年"
      else
        G = [ null, null, 1 ]
        1 - y[2] + "年"

    e[2] = @dic.weeks[ e[2] ]
    Z[2] = @dic.seasons[ Z[2] ]

    G[2] = @dic.era[ G[2] ]
    M[2] = @dic.months[ M[2] ]
    d[2] = d[2] + 1 + "日"
    H[2] = @dic.hours[ H[2] ]
    m[2] = @dic.minutes[ m[2] ]
    s[2] = s[2] + "秒"
    S = [ null, null, now - s[0]]

    { G, p, y,M,d, D,w,e, H,m,s,S, Z }

  index: (tgt, str = default_parse_format)->
    tokens = str.match reg_token

    reg = @parse_reg()
    reg = "^" + tokens.map (token)->
      if val = reg[token[0]]
        val
      else
        token.replace(/([\\\[\]().*?])/g,"\\$1")
    .join("")
    idx = @parse_idx()
    p = y = M = d = H = m = s = S = 0
    data = { p,y,M,d,H,m,s,S }
    for s, p in tgt.match(reg)[1..]
      token = tokens[p]
      if val = idx[token[0]]
        data[token[0]] = val s
    data.p = Math.floor( data.y / @calc.divs.period )
    data.y = data.y - data.p * @calc.divs.period
    data

  parse_reg: ->
    join = (list)->
      "(#{ list.join("|") })"
    G = join @dic.era
    y = "((?:\\d+)年)"
    M = join @dic.months
    d = "((?:\\d+)日)"
    H = @dic.hours
    m = @dic.minutes
    s = "((?:\\d+)秒)"
    S = "((?:\\d+))"
    { G, y,M,d, H,m,s,S }

  parse_idx: ->
    G = (s)=> @dic.era.indexOf(s)
    y = (s)=> s[..-2] - 0
    M = (s)=> @dic.months.indexOf(s)
    d = (s)=> s[..-2] - 1
    H = (s)=> @dic.hours.indexOf(s)
    m = (s)=> @dic.minutes.indexOf(s)
    s = (s)=> s[..-2] - 0
    S = (s)=> s[..-2] - 0
    { G, y,M,d, H,m,s,S }

  parse: (tgt, str = default_parse_format)->
    data = @index tgt, str
    size =
      @table.range.year[data.y] * @calc.msec.day

    @calc.zero.period +
    ( data.p * @calc.msec.period ) +
    ( @table.msec.year[data.y - 1] || 0 ) +
    ( @table.msec.month[size][data.M - 1] || 0 ) +
    ( data.d * @calc.msec.day ) +
    ( data.H * @calc.msec.hour ) +
    ( data.m * @calc.msec.minute ) +
    ( data.s * @calc.msec.second ) +
    ( data.S )

  format: (now, str = default_format_format)->
    o = @slice now - 0
    str.match reg_token
    .map (token)->
      if val = o[token[0]]
        val[2]
      else
        token
    .join("")

# 暦法利用都市から見て、恒星の南中高度、指で数える最大数、可測惑星数、起算時刻。
# 閏日処理法、閏週処理法、閏月処理法、あたりを変数に

EARTH = [
  to_msec('1y')
  2551442881
  to_msec('1d')
  new Date("2019/03/21 6:58").getTime()
  23.4
  [ 35, 135 ]
]

FictionalDate.Gregorian = g = new FictionalDate()
  .planet ...EARTH
  .calendar(
    ["西暦", "紀元前"]
    "1970年1月1日(木)0時0分0秒"
    0
    [4, 100, 400]
    27
  )
  .yeary(
    ['日','月','火','水','木','金','土']
    [1..12].map (i)-> "#{i}月"
    [31, 0,31,30,31,30,31,31,30,31,30,31]
  )
  .seasonly(
    #  中     節    中     節    中     節
    ["立春","雨水","啓蟄","春分","清明","穀雨",
     "立夏","小満","芒種","夏至","小暑","大暑",
     "立秋","処暑","白露","秋分","寒露","霜降",
     "立冬","小雪","大雪","冬至","小寒","大寒"]
  )
  .daily(
    [0...24].map (i)-> "#{i}時"
    [0...60].map (i)-> "#{i}分"
  )
  .init()

FictionalDate.平成 = g.dup()
  .yeary(
    ['月','火','水','木','金','土','日']
  )
  .calendar(
    ["平成", "平成前"]
    "1年1月8日(木)0時0分0秒"
    new Date("1989-1-8").getTime()
  )
  .init()
FictionalDate.令和 = g.dup()
  .yeary(
    ['月','火','水','木','金','土','日']
  )
  .calendar(
    ["令和", "令和前"]
    "1年5月1日(木)0時0分0秒"
    new Date("2019-5-1").getTime()
  )
  .init()

###
FictionalDate.へいきほう = new FictionalDate()
  .planet ...EARTH
  .calendar(
    ["", "前"]
    null
    "1970年1月1日(木)0時0分0秒"
    0
    27
  )
  .yeary(
    ["先勝","友引","先負","仏滅","大安","赤口"]
    ['睦月','如月','弥生','卯月','皐月','水無月','文月','葉月','長月','神無月','霜月','師走']
    null
  )
  .moony(
    ['朔'  ,'既朔','三日月','上弦' ,'上弦','上弦' ,'上弦'  ,'上弦' ,'上弦'  ,'上弦' ,
     '上弦','上弦','十三夜','小望月','満月','十六夜','立待月','居待月','臥待月','更待月',
     '下限','下限','下限'  ,'下限' ,'下限','下限' ,'下限'  ,'下限' ,'晦'    ,'晦'  ]
  )
  .daily(
    ['夜九つ','夜八つ','暁七つ','明六つ','朝五つ','昼四つ','昼九つ','昼八つ','夕七つ','暮六つ','宵五つ','夜四つ']
    ['一つ','二つ','三つ','四つ']
  )
  .init()
###

module.exports = FictionalDate
