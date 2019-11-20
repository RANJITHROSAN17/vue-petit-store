{ Gregorian, 令和, 平成, to_msec, to_tempo_bare } = require "../lib/index.min"
_ = require 'lodash'

g = Gregorian

describe "define", =>
  test 'data', =>
    expect g.calc
    .toMatchSnapshot()
    expect g.dic
    .toMatchSnapshot()
    expect g.calc.msec.period
    .toEqual 12622780800000
    expect g.calc.msec_max.period
    .toEqual 12622780800000
    expect g.calc.msec_min.period
    .toEqual 12622780800000
    expect g.table.msec.year[-1..]
    .toEqual [12622780800000]
    return
  return

describe "令和", =>
  test 'format', =>
    format = "GyMd(e)H Z"
    expect [
      令和.format 100000000000000, format
      令和.format 10000000000000, format
      令和.format new Date("2019-5-1").getTime(), format
      令和.format 1000000000000, format
    ].join("\n")
    .toEqual [
      "令和3120年11月16日(水)18時 立冬"
      "令和268年11月21日(日)2時 小雪"
      "令和1年5月1日(水)0時 穀雨"
      "令和前18年9月9日(日)10時 白露"
    ].join("\n")
    return
  return

describe "平成", =>
  test 'format', =>
    format = "GyMd(e)H Z"
    expect [
      平成.format 100000000000000, format
      平成.format 10000000000000, format
      平成.format 1000000000000, format
      平成.format new Date("1989-1-8").getTime(), format
      平成.format 100000000000, format
    ].join("\n")
    .toEqual [
      "平成3150年11月16日(水)18時 立冬"
      "平成298年11月21日(日)2時 小雪"
      "平成13年9月9日(日)10時 白露"
      "平成1年1月8日(日)0時 "
      "平成前16年3月3日(土)18時 雨水"
    ].join("\n")
    return
  return

describe "Gregorian", =>
  format = require "date-fns/format"
  locale = require "date-fns/locale/ja"
  test '平気法二十四節季', =>
    moon_zero   = to_tempo_bare( g.calc.msec.moon,   g.calc.zero.moon,   new Date("2013-1-1") - 0 ).last_at
    season_zero = to_tempo_bare( g.calc.msec.season, g.calc.zero.season, new Date("2013-1-1") - 0 ).last_at
    list = []
    for i in [0..200]
      msec = moon_zero + i * g.calc.msec.moon
      { last_at, next_at } = to_tempo_bare to_msec("1d"), to_msec("15h"), msec
      list.push last_at - 1
      list.push last_at
      list.push next_at - 1
      list.push next_at
    for i in [0..400]
      msec = season_zero + i * g.calc.msec.season
      { last_at, next_at } = to_tempo_bare to_msec("1d"), to_msec("15h"), msec
      list.push last_at - 1
      list.push last_at
      list.push next_at - 1
      list.push next_at
    list = _.uniq list.sort()

    dst = []
    for msec in list
      { graph } = g.to_tempos msec
      dst.push "#{graph} #{ format msec, "\t yyyy-MM-dd EE HH:mm", { locale } }"
    expect dst
    .toMatchSnapshot()
    return
  return

  test 'format', =>
    format = "GyMd(e)H Z"
    expect [
      g.format 100000000000000, format
      g.format 10000000000000, format
      g.format new Date("2019-5-1").getTime(), format
      g.format 1000000000000, format
      g.format 100000000000, format
      g.format 10000000000, format
      g.format 0, format
      g.format g.calc.zero.period, format
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
    expect [
      g.format g.parse "1970年4月27日"
      g.format g.parse "1973年3月3日"
      g.format g.parse "2001年9月9日"
      g.format g.parse "2286年11月21日"
      g.format g.parse "5138年11月16日"
    ].join("\n")
    .toEqual [
      "西暦1970年4月27日(月)0時0分0秒"
      "西暦1973年3月3日(土)0時0分0秒"
      "西暦2001年9月9日(日)0時0分0秒"
      "西暦2286年11月21日(日)0時0分0秒"
      "西暦5138年11月16日(水)0時0分0秒"
    ].join("\n")
    return



