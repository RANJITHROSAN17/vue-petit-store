{ FancyDate, to_msec, to_tempo_bare } = require "../lib/index.min"
{ Gregorian, MarsGregorian, 平気法 } = FancyDate

format = require "date-fns/format"
locale = require "date-fns/locale/ja"
_ = require 'lodash'


g = Gregorian
mg = MarsGregorian

to_graph = (g, msec)->
  { PI } = Math
  deg_to_rad  = 2 * PI / 360
  { 方向,時角, 真夜中,日の出,南中時刻,日の入 } = g.solor msec
  "#{
    format msec, "yyyy-MM-dd EE HH:mm", { locale }
  }  真夜中.#{
    format 真夜中, "HH:mm", { locale }
  } 日の出.#{
    format 日の出, "HH:mm", { locale }
  } 南中時刻.#{
    format 南中時刻, "HH:mm", { locale }
  } 日の入.#{
    format 日の入, "HH:mm", { locale }
  } 方向.#{
    Math.floor 方向 / deg_to_rad
  } 時角.#{
    Math.floor 時角 / deg_to_rad
  }"


moon_zero   = to_tempo_bare( g.calc.msec.moon,   g.calc.zero.moon,   new Date("2013-1-1") - 0 ).last_at
season_zero = to_tempo_bare( g.calc.msec.season, g.calc.zero.season, new Date("2013-1-1") - 0 ).last_at
list = []
for i in [0.. to_msec("20y") / g.calc.msec.moon]
  msec = moon_zero + i * g.calc.msec.moon
  { last_at, next_at } = to_tempo_bare to_msec("1d"), to_msec("15h"), msec
  list.push last_at - 1
  list.push last_at
  list.push next_at - 1
  list.push next_at
for i in [0.. to_msec("20y") / g.calc.msec.season]
  msec = season_zero + i * g.calc.msec.season
  { last_at, next_at } = to_tempo_bare to_msec("1d"), to_msec("15h"), msec
  list.push last_at - 1
  list.push last_at
  list.push next_at - 1
  list.push next_at
earth_msecs = _.sortedUniq list.sort()


moon_zero   = to_tempo_bare( mg.calc.msec.moon,   mg.calc.zero.moon,   new Date("2013-1-1") - 0 ).last_at
season_zero = to_tempo_bare( mg.calc.msec.season, mg.calc.zero.season, new Date("2013-1-1") - 0 ).last_at
list = []
for i in [0.. to_msec("20y") / mg.calc.msec.moon]
  msec = moon_zero + i * mg.calc.msec.moon
  { last_at, next_at } = to_tempo_bare mg.calc.msec.day, mg.calc.zero.day, msec
  list.push last_at - 1
  list.push last_at
  list.push next_at - 1
  list.push next_at
for i in [0.. to_msec("20y") / mg.calc.msec.season]
  msec = season_zero + i * mg.calc.msec.season
  { last_at, next_at } = to_tempo_bare mg.calc.msec.day, mg.calc.zero.day, msec
  list.push last_at - 1
  list.push last_at
  list.push next_at - 1
  list.push next_at
mars_msecs = _.uniq list.sort()


describe "define", =>
  test 'data', =>
    expect g.calc.msec.period
    .toEqual 12622780800000
    expect g.table.msec.year[-1..]
    .toEqual [12622780800000]
    return
  return

describe "平気法", =>
  test 'calc', =>
    expect 平気法.calc
    .toMatchSnapshot()

  test 'precision', =>
    expect 平気法.precision()
    .toEqual
      leap: [4]
      minute: [1800]

  test '二十四節季と月相', =>
    dst = []
    for msec in earth_msecs
      dst.push "#{
        平気法.format msec, "Gy年Mdd日 E Hm ssss秒"
      } #{
        format msec, "\tyyyy-MM-dd EEE HH:mm", { locale }
      }"
    expect dst
    .toMatchSnapshot()
    return
  return

describe "Gregorian", =>
  test 'calc', =>
    expect g.calc
    .toMatchSnapshot()

  test 'precision', =>
    expect g.precision()
    .toEqual
      leap: [4, -128, 456, -3217]
      minute: [60]

  test 'format', =>
    str = "Gy年Md日(e)H Z"
    expect [
      g.format 100000000000000, str 
      g.format 10000000000000, str 
      g.format new Date("2019-5-1").getTime(), str 
      g.format 1000000000000, str 
      g.format 100000000000, str 
      g.format 10000000000, str 
      g.format 0, str 
      g.format g.calc.zero.period, str 
    ].join("\n")
    .toEqual [
      "西暦5138年11月16日(水)18時 立冬"
      "西暦2286年11月21日(日)2時 小雪"
      "西暦2019年5月1日(水)0時 穀雨"
      "西暦2001年9月9日(日)10時 白露"
      "西暦1973年3月3日(土)18時 雨水"
      "西暦1970年4月27日(月)2時 穀雨"
      "西暦1970年1月1日(木)9時 冬至"
      "紀元前1年1月1日(土)0時 冬至"
    ].join("\n")
    return

  test 'parse → fomat cycle', =>
    str = "Gy年Md日(e)Hms秒"
    expect [
      g.format g.parse("1970年4月27日"), str
      g.format g.parse("1973年3月3日"), str
      g.format g.parse("2001年9月9日"), str
      g.format g.parse("2286年11月21日"), str
      g.format g.parse("5138年11月16日"), str
    ].join("\n")
    .toEqual [
      "西暦1970年4月27日(月)0時0分0秒"
      "西暦1973年3月3日(土)0時0分0秒"
      "西暦2001年9月9日(日)0時0分0秒"
      "西暦2286年11月21日(日)0時0分0秒"
      "西暦5138年11月16日(水)0時0分0秒"
    ].join("\n")
    return
  test '太陽の動き', =>
    dst = []
    for msec in earth_msecs
      dst.push to_graph g, msec
    expect dst
    .toMatchSnapshot()
    return

  test '二十四節季と月相', =>
    dst = []
    for msec in earth_msecs
      dst.push "#{
        format msec, "yyyy-MM-dd", { locale }
      }#{
        format msec, " Y-ww-EEE", { locale }
      }#{
        g.format msec, " Y-ww-E Z Gy年Mdd日 Hm"
      }"
    expect dst
    .toMatchSnapshot()
    return
  return

describe "火星", =>
  test 'calc', =>
    expect mg.calc
    .toMatchSnapshot()
    return

  test 'precision', =>
    expect mg.precision()
    .toEqual
      leap: [1,-2,10,-143,328,-3468]
      minute: [59.66061827956989]

  test '太陽の動き', =>
    dst = []
    for msec in mars_msecs
      dst.push to_graph mg, msec
    expect dst
    .toMatchSnapshot()
    return

  test '二十四節季と月相', =>
    dst = []
    for msec in mars_msecs
      dst.push "#{
        mg.format msec, "Z Gy年Mdd日 E Hm ssss秒"
      } #{
        format msec, "\tyyyy-MM-dd EEE HH:mm", { locale }
      }"
    expect dst
    .toMatchSnapshot()
    return
  return


