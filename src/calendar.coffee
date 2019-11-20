
{
  timezone
  by_tempo
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
default_format_format = "GyMd(e)Hms"

calc_set = (path, o)->
  for key, val of o
    @calc[path][key] = val[path] || val

sub_define = (msec, size)->
  range = [size]
  msec = msec / size
  { range, msec }

daily_define = (msec, day)->
  range = [Math.floor(msec / day)]
  msec = range[0] * day
  { range, msec }

daily_measure = (msec, day)->
  range = [Math.floor(msec / day), Math.ceil(msec / day)]
  { range, msec }

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

  dup: ->
    new @constructor @

  planet: (
    [ revolution = g.calc.msec.year, ecliptic_zero = g.dic.ecliptic_zero]
    [ synodic    = g.calc.msec.moon, synodic_zero  = g.dic.synodic_zero ]
    [ rotation   = g.calc.msec.day,  rotation_zero = g.dic.rotation_zero] 
    axtial_tilt   = g.dic.axtial_tilt,
    geo = g.dic.geo
  )->
    year   = daily_measure revolution, rotation
    moon   = daily_measure    synodic, rotation
    day    = daily_define    rotation, rotation
    calc_set.call @, "range",    { year, moon, day }
    calc_set.call @, "msec",     { year, moon, day }

    [lat, lng] = geo
    tz_offset = rotation / 360 * lng

    Object.assign @dic, { geo, lat, lng, axtial_tilt, ecliptic_zero, synodic_zero, rotation_zero, tz_offset }
    @

  yeary: ( weeks = g.dic.weeks, months = g.dic.months, month_ranges )->
    month = daily_measure @calc.msec.year / months.length, @calc.msec.day
    week  = daily_define  weeks.length * @calc.msec.day,   @calc.msec.day
    calc_set.call @, "range",    { month, week }
    calc_set.call @, "msec",     { month, week }
    Object.assign @dic, { weeks, months, month_ranges }
    @

  moony: (moons)->
    Object.assign @dic, { moons }
    @

  seasonly: (seasons)->
    season = sub_define @calc.msec.year, seasons.length
    calc_set.call @, "range",    { season }
    calc_set.call @, "msec",     { season }
    Object.assign @dic, { seasons }
    @

  daily: (hours = g.dic.hours, minutes = g.dic.minutes)->
    hour   = sub_define @calc.msec.day,  hours.length
    minute = sub_define      hour.msec,  minutes.length
    second = sub_define    minute.msec,  minute.msec / 1000
    calc_set.call @, "range",    { hour, minute, second }
    calc_set.call @, "msec",     { hour, minute, second }
    Object.assign @dic, { hours, minutes }
    @

  calendar: (era = g.dic.era, start = g.dic.start, start_at = g.dic.start_at, leaps = g.dic.leaps)->
    Object.assign @dic, { era, leaps, start, start_at }
    @

  init: ->
    @def_table()
    calc_set.call @, "idx",  @def_idx()
    calc_set.call @, "zero", @def_zero()
    @

  def_table_by_leap_year: ->
    day = @calc.msec.day
    upto = (src)->
      msec = 0
      for i in src
        msec += i * day

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

    { month_ranges, months } = @dic
    unless month_ranges
      month_ranges =
        for str, idx in months
          @calc.range.month[1 - idx % 2]
      month_ranges[1] = 0
    month_sum = 0
    for i in month_ranges
      month_sum += i

    range.month = {}
    for size in years
      a = Array.from month_ranges
      a[1] = size - month_sum
      range.month[size] = a

    year = upto range.year
    period = year[year.length - 1]
    period = daily_define period, day
    calc_set.call @, "msec",     { period }

    month = {}
    for size in years
      month[size * day] = upto range.month[size]

    @table = { range, msec: { year, month } }
    ({ size }, path)->
      switch path
        when 'year'
          year
        when 'month'
          month[size]
        else
          null

  def_table_by_season: ->
    day = @calc.msec.day
    upto = (src)->
      msec = 0
      for i in src
        msec += i * day

    ({ last_at, size, now_idx }, path)-> null

  def_table: ->
    @get_table = 
      if @dic.leaps?
        @def_table_by_leap_year()
      else
        @def_table_by_season()

  def_idx: ->
    week = @dic.weeks.length
    calc_set.call @, "divs", { week }

    [,year, month, day, week, hour, minute, second] = @dic.start.match reg_parse
    year   = year   - 0
    month  = month  - 0
    day    = day    - 0
    hour   = hour   - 0
    minute = minute - 0
    second = second - 0
    week   = @dic.weeks.indexOf week
    season = @dic.seasons.indexOf '春分'
    moon   = 0

    if @dic.leaps?
      [..., full_period] = @dic.leaps
      period = full_period
      calc_set.call @, "divs", { period }

      period = Math.floor year / @calc.divs.period
      year   = year % @calc.divs.period
      { period, year, month, moon, week, day, hour, minute, second, season }
    else
      { year, month, moon, week, day, hour, minute, second, season }

  def_zero: ->
    zero_size = (path, idx = 0)=>
      @dic.start_at - (@calc.idx[path] - idx) * @calc.msec[path]
    zero   = @dic.start_at - @dic.start_at - @dic.tz_offset
    second = zero   + zero_size "second"
    minute = second + zero_size "minute"
    hour   = minute + zero_size "hour"
    day    = hour   + zero_size "day", 1
    week   = day    + zero_size("week") / @calc.divs.week

    # 単純のため平気法。春分点から立春点を求める。
    # season = 0 - @dic.ecliptic_zero + zero_size "season", 13.5
    season = @dic.ecliptic_zero + zero_size "season"
    { since } = to_tempo_bare @calc.msec.year, -season, @dic.start_at
    season = since + zero_size "year", -1
    moon   = 0 - @dic.synodic_zero

    if @dic.leaps?
      year_size = @calc.msec.day * @table.range.year[ @calc.idx.year %% @calc.divs.period ]

      month  = day   - (@table.msec.month[year_size][ @calc.idx.month - 2 ] || 0)
      year   = month - (@table.msec.year[         @calc.idx.year  - 1 ] || 0)
      period = year  + zero_size "period"

      season += zero_size "period"
      { period, week, season, moon, day }
    else
      { week, season, moon, day }


  to_tempos: (utc)->
    drill_down = (base, path, at = utc)=>
      table = @get_table base, path
      if table
        o = to_tempo_by table, base.last_at, at
      else
        b_size = @calc.msec[path]
        o = to_tempo_bare b_size, base.last_at, at
        o.length = base.size / o.size
      o.path = path
      o

    to_tempo_mod = (path, sub, at = utc)=>
      o = to_tempo_bare @calc.msec[path], @calc.zero[path], at
      do2 = to_tempo_bare @calc.msec[sub], @calc.zero[sub], o.next_at
      if do2.last_at <= at
        do3 = to_tempo_bare @calc.msec[sub], @calc.zero[sub], o.next_at + o.size
        o.now_idx += 1
        o.last_at = do2.last_at
        o.next_at = do3.last_at
      else
        do1 = to_tempo_bare @calc.msec[sub], @calc.zero[sub], o.next_at - o.size
        o.last_at = do1.last_at
        o.next_at = do2.last_at
      o


    # season in year_of_planet
    Zz = to_tempo_bare @calc.msec.year, @calc.zero.season, utc # 太陽年

    # 正月中気
    N0_p = Zz.last_at + @calc.msec.season
    N0 = to_tempo_mod "moon", "day", N0_p

    # 今月と中気
    Nn = to_tempo_mod "moon", "day", utc
    Nn.now_idx -= N0.now_idx
    Nn_p = Zz.last_at + @calc.msec.season * ( 1 + Nn.now_idx * 2 )

    # 先月と中気
    Np = to_tempo_mod "moon", "day", Nn.last_at - 1
    Np.now_idx -= N0.now_idx
    Np_p = Zz.last_at + @calc.msec.season * ( 1 + Np.now_idx * 2 )

    unless after_leap_month = Np.next_at <= Np_p
      Nn.is_leap = Nn.next_at <= Nn_p
    if after_leap_month
      Nn.now_idx -= 1
    else
      switch Nn.now_idx
        when -1
          # 太陽年初に0月が出てしまう。昨年末にする。
          Nn.now_idx = @dic.months.length - 1
          Zz.now_idx -= 1
        when @dic.months.length
          # 太陽年末に13月が出てしまう。年初にする。
          Nn.now_idx = 0
          Zz.now_idx += 1

    Z  = drill_down Zz, "season" # 太陽年の二十四節気
    N  = drill_down Nn, 'day'

    # day    in week (曜日)
    w = to_tempo_bare @calc.msec.week, @calc.zero.week,   utc
    e = E = drill_down w,  "day"

    if @dic.leaps?
      p = to_tempo_bare @calc.msec.period, @calc.zero.period, utc
      u = drill_down p, "year"
      u.now_idx = u.now_idx + p.now_idx * @calc.divs.period

      M = drill_down u, "month"
      d = drill_down M, "day"
    else
      u = Zz
      M = Nn
      d = N
      # 旧暦では、週は月初にリセットする。
      e.now_idx = ( M.now_idx + d.now_idx ) % @dic.weeks.length

    #        in year appendix
    D = drill_down u, "day"

    # hour   in day
    H = drill_down d, "hour"
    # minute in day
    m = drill_down H, "minute"
    s = drill_down m, "second"
    now_idx = utc - s.last_at
    S = { now_idx }

    y = Object.assign {}, u
    if 0 < u.now_idx
      G = { now_idx: 0 }
    else
      G = { now_idx: 1 }
      y.now_idx = 1 - u.now_idx

    graph = "#{
      @dic.seasons[Z.now_idx]
    } #{
      if Z.now_idx % 2
        _.padStart ( Z.now_idx + 1 )/ 2, 2,'0'
      else
        "  "
    }\t #{
      y.now_idx
    }年#{
      if Nn.is_leap
        "閏"
      else
        "  "
    }#{
      _.padStart Nn.now_idx + 1, 2,'0'
    }月#{
      _.padStart N.now_idx + 1, 2,'0'
    }日\t"
    { G,u, y,M,d, D,w,e,E, H,m,s,S, Z,N, graph }

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
    H = join @dic.hours
    m = join @dic.minutes
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

  to_label: ({ now_idx, is_leap }, token, length )->
    switch token
      when 'G'
        @dic.era[ now_idx ]
      when 'M'
        "#{
          if is_leap
            "閏"
          else
            ""
        }#{ @dic.months[ now_idx ] }"
      when 'H'
        @dic.hours[ now_idx ]
      when 'm'
        @dic.minutes[ now_idx ]
      when 'e','E'
        @dic.weeks[ now_idx ]
      when 'Z'
        @dic.seasons[ now_idx ]
      when 'N'
        @dic.moons[ now_idx ]

      when 'y', 'u'
        "#{ _.padStart now_idx, length, '0' }年"

      when 'd'
        "#{ _.padStart now_idx + 1, length, '0' }日"
      when 's'
        "#{ _.padStart now_idx, length, '0' }秒"

      when 'S'
        "#{ now_idx / @calc.msec.second }"[2..]

  tempo_list: (tempos, token)->
    switch token[0]
      when 'G'
        throw new Error "request token can't tempos. [#{token}]"

    unless tempo = tempos[token[0]]
      throw new Error "request token can't tempos. [#{token}]"

    { table, length, now_idx, last_at, size, gap } = tempo
    list = []
    if table
      last_at = gap
      for next_at, now_idx in table
        next_at += gap
        size = next_at - last_at
        list.push { now_idx, size, last_at, next_at, last_time: new Date(last_at), next_time: new Date(next_at) }
        last_at = next_at

    if length
      base = last_at - size * now_idx
      for now_idx in [0...length]
        last_at = (now_idx + 0) * size + gap
        next_at = (now_idx + 1) * size + gap
        list.push { now_idx, size, last_at, next_at, last_time: new Date(last_at), next_time: new Date(next_at) }
    list

  ranges: (utc, token)->
    @tempo_list @to_tempos(utc), token

  parse: (tgt, str = default_parse_format)->
    { p,y,M,d,H,m,s,S } = @index tgt, str

    in_period =
      if @dic.leaps?
        size =
          @table.range.year[y] * @calc.msec.day
        ( @table.msec.year[y - 1] || 0 ) +
        ( @table.msec.month[size][M - 1] || 0 )
      else
        ( y * @calc.msec.year) +
        ( M * @calc.msec.month )

    @calc.zero.period +
    ( p * @calc.msec.period ) +
    in_period +
    # dic.season
    ( d * @calc.msec.day ) +
    ( H * @calc.msec.hour ) +
    ( m * @calc.msec.minute ) +
    ( s * @calc.msec.second ) +
    ( S )

  format: (utc, str = default_format_format)->
    o = @to_tempos utc
    str.match reg_token
    .map (token)=>
      if val = o[token[0]]
        @to_label val, token[0], token.length
      else
        token
    .join("")

# 暦法利用都市から見て、恒星の南中高度、指で数える最大数、可測惑星数、起算時刻。
# 閏日処理法、閏週処理法、閏月処理法、あたりを変数に

EARTH = [
  [31556925147.0, new Date("2019/03/21 06:58").getTime()]
  [ 2551442889.6, new Date("2019/01/06 10:28").getTime()]
  [to_msec('1d'), 0] # LOD ではなく、暦上の1日。Unix epoch では閏秒を消し去るため。
  23.4397
  [ 35, 135 ]
]

FictionalDate.Gregorian = g = new FictionalDate()
  .planet ...EARTH
  .calendar(
    ["西暦", "紀元前"]
    "1970年1月1日(木)0時0分0秒"
    0
    [4, 100, 400]
  )
  .yeary(
    ['日','月','火','水','木','金','土']
    [1..12].map (i)-> "#{i}月"
    [31, 0,31,30,31,30,31,31,30,31,30,31]
  )
  .seasonly(
    #   節    中     節    中     節    中 
    ["立春","雨水","啓蟄","春分","清明","穀雨",
     "立夏","小満","芒種","夏至","小暑","大暑",
     "立秋","処暑","白露","秋分","寒露","霜降",
     "立冬","小雪","大雪","冬至","小寒","大寒"]
  )
  .moony(
    ['朔'  ,'既朔','三日月','上弦' ,'上弦','上弦' ,'上弦'  ,'上弦' ,'上弦'  ,'上弦' ,
      '上弦','上弦','十三夜','小望月','満月','十六夜','立待月','居待月','臥待月','更待月',
      '下限','下限','下限'  ,'下限' ,'下限','下限' ,'下限'  ,'下限' ,'晦'    ,'晦'  ]
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
    "1年1月8日(日)0時0分0秒"
    new Date("1989-1-8").getTime()
  )
  .init()
FictionalDate.令和 = g.dup()
  .yeary(
    ['月','火','水','木','金','土','日']
  )
  .calendar(
    ["令和", "令和前"]
    "1年5月1日(水)0時0分0秒"
    new Date("2019-5-1").getTime()
  )
  .init()

FictionalDate.平気法 = new FictionalDate()
  .planet ...EARTH
  .calendar(
    ["", "前"]
    "1970年1月1日(木)0時0分0秒"
    0
    null
  )
  .yeary(
    ["先勝","友引","先負","仏滅","大安","赤口"]
    ['睦月','如月','弥生','卯月','皐月','水無月','文月','葉月','長月','神無月','霜月','師走']
  )
  .seasonly(
    #   節    中     節    中     節    中 
    ["立春","雨水","啓蟄","春分","清明","穀雨",
     "立夏","小満","芒種","夏至","小暑","大暑",
     "立秋","処暑","白露","秋分","寒露","霜降",
     "立冬","小雪","大雪","冬至","小寒","大寒"]
  )
  .moony(
    ['朔'  ,'既朔','三日月','上弦' ,'上弦','上弦' ,'上弦'  ,'上弦' ,'上弦'  ,'上弦' ,
      '上弦','上弦','十三夜','小望月','満月','十六夜','立待月','居待月','臥待月','更待月',
      '下限','下限','下限'  ,'下限' ,'下限','下限' ,'下限'  ,'下限' ,'晦'    ,'晦'  ]
  )
  .daily(
    ['夜九つ','夜八つ','暁七つ',
      '明六つ','朝五つ','昼四つ',
      '昼九つ','昼八つ','夕七つ',
      '暮六つ','宵五つ','夜四つ'
    ]
    ['一つ','二つ','三つ','四つ']
  )
  .init()

module.exports = FictionalDate

{ PI, atan2, sin, cos, tan } = Math
rad = PI / 180
e = rad * 23.4397;
right_ascension = ( l, b )-> atan2 sin(l) * cos(e) - tan(b) * sin(e),  cos(l)
declination     = ( l, b )-> asin  sin(b) * cos(e) + cos(b) * sin(e) * sin(l)
azmith   = ( H, phi, dec )-> atan2 sin(H), cos(H) * sin(phi) - tan(dec) * cos(phi)
altitude = ( H, phi, dec )-> asin  sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(H)
siderealTime    = ( d,lw )-> rad * ( 280.16 + 360.9856235 * d ) - lw
