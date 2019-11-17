{ Gregorian, 令和, 平成, to_msec } = require "../lib/index.min"

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

describe "令和", =>
  test 'format', =>
    format = "GGyyyyMMdd(eee)HH ZZ"
    expect [
      令和.format 100000000000000, format
      令和.format 10000000000000, format
      令和.format new Date("2019-5-1").getTime(), format
      令和.format 1000000000000, format
      令和.format 100000000000, format
    ].join("\n")
    .toEqual [
      "令和3120年11月16日(水)18時 立冬"
      "令和2286年11月21日(日)2時 小雪"
      "令和1年5月1日(水)0時 穀雨"
      "令和前18年9月9日(日)10時 白露"
      "令和前46年3月3日(土)18時 雨水"
    ].join("\n")
    return
  return

describe "平成", =>
  test 'format', =>
    format = "GGyyyyMMdd(eee)HH ZZ"
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
  test '2019年', =>
    # https://eco.mtk.nao.ac.jp/cgi-bin/koyomi/cande/phenomena_s.cgi
    format = "GGyyyyMMdd(eee) HHmm ZZ"

    expect [
      g.format new Date("2019/02/19 08:04"), format
      g.format new Date("2019/03/06 06:10"), format
      g.format new Date("2019/03/21 06:58"), format
      g.format new Date("2019/04/05 10:51"), format
      g.format new Date("2019/04/20 17:55"), format
      g.format new Date("2019/05/06 04:03"), format
      g.format new Date("2019/05/21 16:59"), format
      g.format new Date("2019/06/06 08:06"), format
      g.format new Date("2019/06/22 00:54"), format
      g.format new Date("2019/07/07 18:21"), format
      g.format new Date("2019/07/23 11:50"), format
      g.format new Date("2019/08/08 04:13"), format
      g.format new Date("2019/08/23 19:02"), format
      g.format new Date("2019/09/08 07:17"), format
      g.format new Date("2019/09/23 16:50"), format
      g.format new Date("2019/10/08 23:06"), format
      g.format new Date("2019/10/24 02:20"), format
      g.format new Date("2019/11/08 02:24"), format
      g.format new Date("2019/11/22 23:59"), format
      g.format new Date("2019/12/07 19:18"), format
      g.format new Date("2019/12/22 13:19"), format
    ].join("\n")
    .toEqual [
      "西暦2019年2月19日(火) 8時4分 雨水"
      "西暦2019年3月6日(水) 6時10分 啓蟄"
      "西暦2019年3月21日(木) 6時58分 啓蟄"
      "西暦2019年4月5日(金) 10時51分 春分"
      "西暦2019年4月20日(土) 17時55分 穀雨"
      "西暦2019年5月6日(月) 4時3分 立夏"
      "西暦2019年5月21日(火) 16時59分 小満"
      "西暦2019年6月6日(木) 8時6分 芒種"
      "西暦2019年6月22日(土) 0時54分 夏至"
      "西暦2019年7月7日(日) 18時21分 小暑"
      "西暦2019年7月23日(火) 11時50分 大暑"
      "西暦2019年8月8日(木) 4時13分 立秋"
      "西暦2019年8月23日(金) 19時2分 処暑"
      "西暦2019年9月8日(日) 7時17分 白露"
      "西暦2019年9月23日(月) 16時50分 秋分"
      "西暦2019年10月8日(火) 23時6分 寒露"
      "西暦2019年10月24日(木) 2時20分 霜降"
      "西暦2019年11月8日(金) 2時24分 立冬"
      "西暦2019年11月22日(金) 23時59分 小雪"
      "西暦2019年12月7日(土) 19時18分 大雪"
      "西暦2019年12月22日(日) 13時19分 冬至"
    ].join("\n")

  test 'format', =>
    format = "GGyyyyMMdd(eee)HH ZZ"
    expect [
      g.format 100000000000000, format
      g.format 10000000000000, format
      g.format new Date("2019-5-1").getTime(), format
      g.format 1000000000000, format
      g.format 100000000000, format
      g.format 10000000000, format
      g.format 0, format
      g.format g.calc.zero.period, format
    ]
    .toEqual [
      "西暦5138年11月16日(水)18時 立冬"
      "西暦2286年11月21日(日)2時 小雪"
      "西暦2019年5月1日(水)0時 穀雨"
      "西暦2001年9月9日(日)10時 白露"
      "西暦1973年3月3日(土)18時 雨水"
      "西暦1970年4月27日(月)2時 穀雨"
      "西暦1970年1月1日(木)9時 冬至"
      "紀元前1年1月1日(土)9時 冬至"
    ]
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
    return

  test 'parse → fomat cycle', =>
    expect g.format g.parse "1970年4月27日"
    .toEqual "西暦1970年4月27日(月)9時0分0秒"

    expect g.format g.parse "1973年3月3日"
    .toEqual "西暦1973年3月3日(土)9時0分0秒"

    expect g.format g.parse "2001年9月9日"
    .toEqual "西暦2001年9月9日(日)9時0分0秒"

    expect g.format g.parse "2286年11月21日"
    .toEqual "西暦2286年11月21日(日)9時0分0秒"

    expect g.format g.parse "5138年11月16日"
    .toEqual "西暦5138年11月16日(水)9時0分0秒"

    return
  return


