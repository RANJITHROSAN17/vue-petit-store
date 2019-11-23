  
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
    @calc[path][key] = val?[path] || val

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

export class FancyDate
  constructor: (o)->
    if o
      { dic, calc } = o
      @dic  = _.cloneDeep dic
      @calc = _.cloneDeep calc
    else
      @dic = {}
      @calc =
        eras: []
        divs: {}
        idx:  {}
        gap:  {}
        zero: {}
        msec: {}
        range: {}

  dup: ->
    new @constructor @

  planet: (
    [ revolution = g.calc.msec.year, spring = g.dic.spring]
    [ synodic    = g.calc.msec.moon, synodic_zero  = g.dic.synodic_zero ]
    [ rotation   = g.calc.msec.day,  rotation_zero = g.dic.rotation_zero] 
    axtial_tilt   = g.dic.axtial_tilt,
    geo = g.dic.geo
  )->
    year   = daily_measure revolution, rotation
    moon   = daily_measure    synodic, rotation
    day    = daily_define    rotation, rotation
    calc_set.call @, "range", { year, moon, day }
    calc_set.call @, "msec",  { year, moon, day }

    [lat, lng] = geo
    tz_offset = rotation / 360 * lng

    Object.assign @dic, { geo, lat, lng, axtial_tilt, spring, synodic_zero, rotation_zero, tz_offset }
    @

  rolls: ( weeks = g.dic.weeks, etos = g.dic.etos )->
    week  = daily_define  weeks.length * @calc.msec.day, @calc.msec.day
    calc_set.call @, "range", { week }
    calc_set.call @, "msec",  { week }
    Object.assign @dic, { weeks, etos }
    @

  era: ( era, eras = [] )->
    Object.assign @dic, { era, eras }
    @

  yeary: ( months = g.dic.months, month_ranges )->
    month = daily_measure @calc.msec.year / months.length, @calc.msec.day
    calc_set.call @, "range", { month }
    calc_set.call @, "msec",  { month }
    Object.assign @dic, { months, month_ranges }
    @

  moony: (moons)->
    Object.assign @dic, { moons }
    @

  seasonly: (seasons)->
    season = sub_define @calc.msec.year, seasons.length
    calc_set.call @, "range", { season }
    calc_set.call @, "msec",  { season }
    Object.assign @dic, { seasons }
    @

  daily: (hours = g.dic.hours, minutes = g.dic.minutes, is_solor = false)->
    hour   = sub_define @calc.msec.day,  hours.length
    if is_solor
      minute = sub_define      hour.msec,  minutes.length
      second = sub_define    minute.msec,  minute.msec / 1000
      calc_set.call @, "range", { hour, minute, second }
      calc_set.call @, "msec",  { hour, minute, second }
    else
      minute = sub_define      hour.msec,  minutes.length
      second = sub_define    minute.msec,  minute.msec / 1000
      calc_set.call @, "range", { hour, minute, second }
      calc_set.call @, "msec",  { hour, minute, second }
    Object.assign @dic, { hours, minutes, is_solor }
    @

  calendar: (start = g.dic.start, start_at = g.dic.start_at, leaps = null)->
    Object.assign @dic, { leaps, start, start_at }
    @

  init: ->
    @def_table()
    Object.assign @calc.idx,  @def_idx()
    Object.assign @calc.zero, @def_zero()

    zero = @calc.zero.era
    list =
      for [ title, msec ], idx in @dic.eras
        { u } = @to_tempos msec
        a = [ title, msec, u.now_idx]
        @calc.eras.push a
        msec - zero
    list.push Infinity
    @table.msec.era = list
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
    calc_set.call @, "msec", { period }

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
    @table = { range: {}, msec: {} }
    (o, path)-> null

  def_table: ->
    @get_table = 
      if @dic.leaps?
        @def_table_by_leap_year()
      else
        @def_table_by_season()

  def_idx: ->
    week = @dic.weeks.length
    eto  = @dic.etos.length
    Object.assign @calc.divs, { week, eto }

    [,year, month, day, week, hour, minute, second] = @dic.start.match reg_parse
    year   = year   - 0
    month  = month  - 0
    day    = day    - 0
    hour   = hour   - 0
    minute = minute - 0
    second = second - 0
    eto    = 56
    week   = @dic.weeks.indexOf week
    season = @dic.seasons.indexOf '春分'
    moon   = 0

    if @dic.leaps?
      [..., full_period] = @dic.leaps
      period = full_period
      Object.assign @calc.divs, { period }

      period = Math.floor year / @calc.divs.period
      year   = year % @calc.divs.period

    { period, year, month, moon, week, eto, day, hour, minute, second, season }

  def_zero: ->
    zero_size = (path, idx = 0)=>
      0 - (@calc.idx[path] - idx) * @calc.msec[path]
    zero   = @dic.start_at - @dic.tz_offset
    second = zero   + zero_size "second"
    minute = second + zero_size "minute"
    hour   = minute + zero_size "hour"
    day    = hour   + zero_size "day", 1
    week   = day    + zero_size("week") / @calc.divs.week

    # JD
    jd = -2440587.5 * @calc.msec.day
    ld = jd + 2299159.5 * @calc.msec.day
    mjd = jd + 2400000.5 * @calc.msec.day

    # 単純のため平気法。
    season = @dic.spring + zero_size "season" # 立春点
    { since } = to_tempo_bare @calc.msec.year, @dic.start_at, season
    season = since + zero_size "year"
    moon   = 0 - @dic.synodic_zero

    if @dic.leaps?
      year_size = @calc.msec.day * @table.range.year[ @calc.idx.year %% @calc.divs.period ]

      month  = day   - (@table.msec.month[year_size][ @calc.idx.month - 2 ] || 0)
      year   = month - (@table.msec.year[             @calc.idx.year  - 1 ] || 0)
      period = year  + zero_size "period"

      season += zero_size "period"

    # 元号
    era = @dic.eras[0]?[1] || Infinity
    @calc.eras = []
    if @dic.leaps?
      if period < era
        era = period + @table.msec.year[0]
        @calc.eras = [[@dic.era, era, 1]]
    else
      if season < era
        era = season + @calc.msec.year
        @calc.eras = [[@dic.era, era, 1]]

    { period, era, week, season, moon, day, jd,ld,mjd }

###
http://bakamoto.sakura.ne.jp/buturi/2hinode.pdf
ベクトルで
a1 = e1 * cos(lat/360) + e3 * sin(lat/360)
a2 = e3 * cos(lat/360) - e1 * sin(lat/360)
T = (赤緯, 時角)->
  a1 * sin(赤緯) + cos(赤緯) * (a2 * cos(時角) - e2 * sin(時角))
T = ( lat, 赤緯, 時角 )->
  e1 * ( cos(lat/360) * sin(赤緯) - sin(lat/360) * cos(赤緯) * cos(時角) ) +
  e2 * (-cos(赤緯) * sin(時角)) +
  e3 * ( sin(lat/360) * sin(赤緯) + cos(lat/360) * cos(赤緯) * cos(時角) )

K   = g.dic.axtial_tilt / 360
高度 = -50/60
時角 = ( lat, 高度, 赤緯 )->
  acos(( sin(高度) - sin(lat/360) * sin(赤緯) ) / cos(lat/360) * cos(赤緯) )
方向 = ( lat, 高度, 赤緯, 時角 )->
  acos(( cos(lat/360) * sin(赤緯) - sin(lat/360) * cos(赤緯) * cos(時角) ) / cos(高度) )
季節 = 春分点からの移動角度
赤緯 = asin( sin(K) * sin(季節) )
赤経 = atan( tan(季節) * cos(K) )
南中時刻 = ->
  正午 + 時角 + ( 赤経 - 季節 ) + 平均値 + tz_offset
日の出 = ->
  南中時刻 - 時角
日の入 = ->
  南中時刻 + 時角
###

  solor: (utc, idx = 2, { last_at, next_at } = to_tempo_bare @calc.msec.day, @calc.zero.day, utc )->
    days = [
        6      # golden hour end         / golden hour
      -18 / 60 # sunrise bottom edge end / sunset bottom edge start
      -50 / 60 # sunrise top edge start  / sunset top edge end
       -6      # dawn                    / dusk
      -12      # nautical dawn           / nautical dusk
      -18      # night end               / night
    ]
    { asin, acos, atan, sin, cos, tan, PI } = Math
    deg_to_rad  = 2 * PI / 360
    year_to_rad = 2 * PI / @calc.msec.year
    rad_to_day  = @calc.msec.day / ( 2 * PI )
    deg_to_day  = @calc.msec.day / 360

    高度 = days[idx]        * deg_to_rad
    K   = @dic.axtial_tilt * deg_to_rad
    lat = @dic.lat         * deg_to_rad

    T0  = to_tempo_bare @calc.msec.year, @calc.zero.season, utc

    # 南中差分の計算がテキトウになってしまった。あとで検討。
    南中差分A = Math.floor 2   * deg_to_day * sin(( T0.since              ) * year_to_rad     )
    南中差分B = Math.floor 2.5 * deg_to_day * sin(( T0.since + 1296000000 ) * year_to_rad * 2 )
    南中時刻 = ( last_at + next_at ) / 2 + 南中差分A + 南中差分B
    真夜中 = last_at + 南中差分A + 南中差分B

    T1 = to_tempo_bare @calc.msec.year, @dic.spring, 南中時刻

    spring = T1.last_at
    季節 = T1.since * year_to_rad
    赤緯 = asin( sin(K) * sin(季節) )
    赤経 = atan( tan(季節) * cos(K) )
    時角 = acos(( sin(高度) - sin(lat) * sin(赤緯) ) / (cos(lat) * cos(赤緯)) )
    方向 = acos(( cos(lat) * sin(赤緯) - sin(lat) * cos(赤緯) * cos(時角) ) / cos(高度) )

    日の出 = Math.floor 南中時刻 - 時角 * rad_to_day
    日の入 = Math.floor 南中時刻 + 時角 * rad_to_day
    { 時角,方向, last_at, 真夜中,日の出,南中時刻,日の入, next_at }

  to_tempo_by_solor: (utc, day)->
    { 日の出, 南中時刻, 日の入 } = @solor utc, 2, day
    size = @dic.hours.length / 4

    list = []
    next_at = 0
    msec = ( 日の出 - day.last_at ) / size
    for idx in [0        ... 1 * size]
      next_at += msec
      list.push Math.floor next_at

    next_at = 日の出 - day.last_at
    msec = ( 日の入 - 日の出 ) / ( 2 * size )
    for idx in [1 * size ... 3 * size]
      next_at += msec
      list.push Math.floor next_at

    next_at = day.size
    msec = ( day.next_at - 日の入 ) / size

    tails = []
    for idx in [3 * size ... 4 * size]
      tails.push Math.ceil next_at
      next_at -= msec
    list.push ...tails.reverse()
    to_tempo_by list, day.last_at, utc

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

    to_tempo_mod = (path, sub, write_at = utc)=>
      { now_idx, next_at, size, zero } = to_tempo_bare @calc.msec[path], @calc.zero[path], write_at
      do2 = to_tempo_bare @calc.msec[sub], @calc.zero[sub], next_at
      if do2.last_at <= write_at
        do3 = to_tempo_bare @calc.msec[sub], @calc.zero[sub], next_at + size
        now_idx += 1
        last_at = do2.last_at
        next_at = do3.last_at

      else
        do1 = to_tempo_bare @calc.msec[sub], @calc.zero[sub], next_at - size
        last_at = do1.last_at
        next_at = do2.last_at
      size   =  next_at -  last_at
      remain =  next_at - write_at
      since  = write_at -  last_at
      timeout = remain
      { last_at, write_at, next_at, timeout, since, remain, zero, now_idx, size }

    J = to_tempo_bare @calc.msec.day, @calc.zero.jd, utc # ユリウス日

    # season in year_of_planet
    Zz = to_tempo_bare @calc.msec.year, @calc.zero.season, utc # 太陽年
    Z  = drill_down Zz, "season" # 太陽年の二十四節気

    # 正月中気
    N0_p = Zz.last_at + @calc.msec.season
    N0 = to_tempo_mod "moon", "day", N0_p

    # 今月と中気
    Nn = to_tempo_mod "moon", "day"
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
          Zz = to_tempo_bare Zz.size, Zz.zero + Zz.size, utc
        when @dic.months.length
          # 太陽年末に13月が出てしまう。年初にする。
          Nn.now_idx = 0
          Zz = to_tempo_bare Zz.size, Zz.zero - Zz.size, utc

    N  = drill_down Nn, 'day'

    if @dic.leaps?
      p = to_tempo_bare @calc.msec.period, @calc.zero.period, utc
      u = drill_down p, "year"
      u.now_idx += p.now_idx * @calc.divs.period
      M = drill_down u, "month"
      d = drill_down M, "day"
    else
      u = Zz
      M = Nn
      d = N

    # day    in week (曜日)
    w0 = to_tempo_bare @calc.msec.week, @calc.zero.week ,u.last_at
    w = drill_down w0, "week"

    Y =
      now_idx: u.now_idx
    if u.next_at < w.next_at
      # 年末最終週は、翌年初週
      Y.now_idx += 1
      w.now_idx  = 0

    e = E = drill_down w, "day"
    unless @dic.leaps?
      # 旧暦では、週は月初にリセットする。
      e.now_idx = ( M.now_idx + d.now_idx ) % @dic.weeks.length

    # day    in year appendix
    D = drill_down u, "day"
    if @dic.is_solor
      # hour   in day
      H = @to_tempo_by_solor utc, d
      size = H.size / @dic.minutes.length
      m = to_tempo_bare size, H.last_at, utc
      s = to_tempo_bare 1000, m.last_at, utc
    else
      # hour   in day
      H = drill_down d, "hour"
      m = drill_down H, "minute"
      s = drill_down m, "second"

    # minute in day
    now_idx = utc - s.last_at
    S = { now_idx }

    T =
      label: [( u.now_idx + @calc.idx.eto )% 60]

    G = {}
    if @table.msec.era?
      era_base = to_tempo_by @table.msec.era, @calc.zero.era, utc
      era = @calc.eras[era_base.now_idx]
      if era?[0]
        u.now_idx += 1 - era[2]
        G.label = era[0]

    y = Object.assign {}, u
    if y.now_idx < 1
      G.label = "紀元前"
      y.now_idx = 1 - y.now_idx

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
    { G,u, y,M,d, D, Y,w,e,E, H,m,s,S, Z,N, J, era, graph }

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
    p = y = M = d = H = m = s = S = J = 0
    data = { p,y,M,d,H,m,s,S, J }
    for s, p in tgt.match(reg)[1..]
      token = tokens[p]
      if val = idx[token[0]]
        data[token[0]] = val s
    if @dic.leaps?
      data.p = Math.floor( data.y / @calc.divs.period )
      data.y = data.y - data.p * @calc.divs.period
    data

  parse_reg: ->
    join = (list)->
      "(#{ list.join("|") })"
    G = join [@dic.era, "紀元前"]
    y = "((?:\\d)+年)"
    M = join @dic.months
    d = "((?:\\d)+日)"
    H = join @dic.hours
    m = join @dic.minutes
    s = "((?:\\d)+秒)"
    S = "(\\d+)"
    J = "([\\d.]+)"
    { G, y,M,d, H,m,s,S, J }

  parse_idx: ->
    G = (s)=> @dic.era.indexOf(s)
    y = (s)=> s[..-2] - 0
    M = (s)=> @dic.months.indexOf(s)
    d = (s)=> s[..-2] - 1
    H = (s)=> @dic.hours.indexOf(s)
    m = (s)=> @dic.minutes.indexOf(s)
    s = (s)=> s[..-2] - 0
    S = (s)=> s[..-2] - 0
    J = (s)=> s - 0
    { G, y,M,d, H,m,s,S, J }

  to_label: (o, token, length )->
    switch token
      when 'G'
        o.label
      when 'M'
        "#{
          if o.is_leap
            "閏"
          else
            ""
        }#{ @dic.months[ o.now_idx ] }"
      when 'H'
        @dic.hours[ o.now_idx ]
      when 'm'
        @dic.minutes[ o.now_idx ]
      when 'e','E'
        @dic.weeks[ o.now_idx ]
      when 'Z'
        @dic.seasons[ o.now_idx ]
      when 'N'
        @dic.moons[ o.now_idx ]

      when 'w'
        "#{ _.padStart o.now_idx + 1, length, '0' }"
      when 'd'
        "#{ _.padStart o.now_idx + 1, length, '0' }"
      when 'D'
        "#{ _.padStart o.now_idx + 1, length, '0' }"

      when 'J'
        "#{ _.padStart o.now_idx, length, '0' }"

      when 'Y', 'y', 'u'
        "#{ _.padStart o.now_idx, length, '0' }"

      when 's'
        "#{ _.padStart o.now_idx, length, '0' }"

      when 'S'
        "#{ o.now_idx / @calc.msec.second }"[2..]

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
    { p,y,M,d,H,m,s,S, J } = @index tgt, str

    if J
      return @calc.zero.jd + J * @calc.msec.day 

    ( d * @calc.msec.day ) +
    ( H * @calc.msec.hour ) +
    ( m * @calc.msec.minute ) +
    ( s * @calc.msec.second ) +
    ( S ) +
    if @dic.leaps?
      size =
        @table.range.year[y] * @calc.msec.day

      @calc.zero.period +
      ( p * @calc.msec.period ) +
      ( @table.msec.year[y - 1] || 0 ) +
      ( @table.msec.month[size][M - 1] || 0 )
    else
      @calc.zero.season +
      ( y * @calc.msec.year) +
      ( M * @calc.msec.month )

  format: (utc, str = default_format_format)->
    o = @to_tempos utc
    str.match reg_token
    .map (token)=>
      if val = o[token[0]]
        @to_label val, token[0], token.length
      else
        token
    .join("")

module.exports = FancyDate
