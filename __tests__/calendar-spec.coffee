{ FictionalDate, to_timer, to_msec } = require "../lib/index.min"

g = FictionalDate.Gregorian

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

describe "standard use", =>
  test 'format', =>
    expect g.format 100000000000000
    .toEqual "西暦5138年霜月16日(水)18時"

    expect g.format 10000000000000
    .toEqual "西暦2286年霜月21日(日)2時"

    expect g.format 1000000000000
    .toEqual "西暦2001年長月9日(日)10時"

    expect g.format 100000000000
    .toEqual "西暦1973年弥生3日(土)18時"

    expect g.format 10000000000
    .toEqual "西暦1970年卯月27日(月)2時"

    expect g.format 0
    .toEqual "西暦1970年睦月1日(木)9時"
    return
  return
