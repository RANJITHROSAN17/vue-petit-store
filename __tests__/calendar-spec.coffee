{ Gregorian, 令和, to_msec } = require "../lib/index.min"

g = Gregorian

describe "define", =>
  test 'data', =>
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

describe "Gregorian", =>
  test 'format', =>
    expect g.format 100000000000000
    .toEqual "西暦5138年11月16日(水)18時"

    expect g.format 10000000000000
    .toEqual "西暦2286年11月21日(日)2時"

    expect g.format 1000000000000
    .toEqual "西暦2001年9月9日(日)10時"

    expect g.format 100000000000
    .toEqual "西暦1973年3月3日(土)18時"

    expect g.format 10000000000
    .toEqual "西暦1970年4月27日(月)2時"

    expect g.format 0
    .toEqual "西暦1970年1月1日(木)9時"

    expect g.format g.calc.zero.period
    .toEqual "紀元前1年1月1日(土)9時"

    expect g.format new Date("2019-5-1").getTime()
    .toEqual "西暦2019年5月1日(水)0時"
    return

  test 'parse', =>
    expect g.parse "1970年1月1日"
    .toEqual 0

    expect g.parse "1970年4月27日"
    .toEqual 10022400000

    expect g.parse "1973年3月3日"
    .toEqual 99964800000

    expect g.parse "2001年9月9日"
    .toEqual 999993600000

    expect g.parse "2286年11月21日"
    .toEqual 10000022400000

    expect g.parse "5138年11月16日"
    .toEqual 99999964800000

  test 'parse → fomat cycle', =>
    expect g.format g.parse "1970年4月27日"
    .toEqual "西暦1970年4月27日(月)9時"

    expect g.format g.parse "1973年3月3日"
    .toEqual "西暦1973年3月3日(土)9時"

    expect g.format g.parse "2001年9月9日"
    .toEqual "西暦2001年9月9日(日)9時"

    expect g.format g.parse "2286年11月21日"
    .toEqual "西暦2286年11月21日(日)9時"

    expect g.format g.parse "5138年11月16日"
    .toEqual "西暦5138年11月16日(水)9時"

    return


describe "令和", =>
  test 'format', =>
    expect 令和.format 0
    .toEqual "令和前49年睦月1日(木)9時"

    expect 令和.format 100000000000000
    .toEqual "西暦5138年霜月16日(水)18時"

    expect 令和.format 10000000000000
    .toEqual "西暦2286年霜月21日(日)2時"

    expect 令和.format 1000000000000
    .toEqual "西暦2001年長月9日(日)10時"

    expect 令和.format 100000000000
    .toEqual "西暦1973年弥生3日(土)18時"

    expect 令和.format 10000000000
    .toEqual "西暦1970年卯月27日(月)2時"
    return
  return
