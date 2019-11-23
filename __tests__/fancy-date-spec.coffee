{ FancyDate, to_msec, to_tempo_bare } = require "../lib/index.min"
{ Gregorian, Mars, 平気法 } = FancyDate

format = require "date-fns/format"
locale = require "date-fns/locale/ja"
_ = require 'lodash'


g = Gregorian

to_graph = (g, msec)->
  { PI } = Math
  deg_to_rad  = 2 * PI / 360
  { 方向,時角, 真夜中,日の出,南中時刻,日の入 } = g.solor msec
  "#{
    format msec, "\t yyyy-MM-dd EE HH:mm", { locale }
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

ERAS = [
  ["大化",    1956842]
  ["白雉",    1958551]
  ["朱鳥",    1971845]
  ["大宝",    1977221]
  ["慶雲",    1978361]
  ["和銅",    1979692]
  ["霊亀",    1982487]
  ["養老",    1983300]
  ["神亀",    1985561]
  ["天平",    1987570]
  ["天平感宝", 1994754]
  ["天平勝宝", 1994861]
  ["天平宝字", 1997801]
  ["天平神護", 2000506]
  ["神護景雲", 2001460]
  ["宝亀",    2002596]
  ["天応",    2006348]
  ["延暦",    2006956]
  ["大同",    2015608]
  ["弘仁",    2017203]
  ["天長",    2022062]
  ["承和",    2025721]
  ["嘉祥",    2030987]
  ["仁寿",    2032037]
  ["斉衡",    2033338]
  ["天安",    2034156]
  ["貞観",    2034947]
  ["元慶",    2041534]
  ["仁和",    2044374]
  ["寛平",    2045915]
  ["昌泰",    2049192]
  ["延喜",    2050391]
  ["延長",    2058332]
  ["承平",    2061241]
  ["天慶",    2063835]
  ["天暦",    2067084]
  ["天徳",    2070927]
  ["応和",    2072127]
  ["康保",    2073390]
  ["安和",    2074871]
  ["天禄",    2075473]
  ["天延",    2076827]
  ["貞元",    2077765]
  ["天元",    2078637]
  ["永観",    2080247]
  ["寛和",    2080968]
  ["永延",    2081684]
  ["永祚",    2082543]
  ["正暦",    2082985]
  ["長徳",    2084565]
  ["長保",    2085974]
  ["寛弘",    2087989]
  ["長和",    2091095]
  ["寛仁",    2092658]
  ["治安",    2094054]
  ["万寿",    2095305]
  ["長元",    2096765]
  ["長暦",    2099951]
  ["長久",    2101268]
  ["寛徳",    2102729]
  ["永承",    2103251]
  ["天喜",    2105699]
  ["康平",    2107754]
  ["治暦",    2110296]
  ["延久",    2111636]
  ["承保",    2113595]
  ["承暦",    2114771]
  ["永保",    2115974]
  ["応徳",    2117063]
  ["寛治",    2118215]
  ["嘉保",    2121029]
  ["永長",    2121740]
  ["承徳",    2122098]
  ["康和",    2122725]
  ["長治",    2124361]
  ["嘉承",    2125157]
  ["天仁",    2126007]
  ["天永",    2126697]
  ["永久",    2127818]
  ["元永",    2129522]
  ["保安",    2130267]
  ["天治",    2131737]
  ["大治",    2132375]
  ["天承",    2134214]
  ["長承",    2134785]
  ["保延",    2135777]
  ["永治",    2138033]
  ["康治",    2138318]
  ["天養",    2138991]
  ["久安",    2139493]
  ["仁平",    2141505]
  ["久寿",    2142894]
  ["保元",    2143425]
  ["平治",    2144511]
  ["永暦",    2144796]
  ["応保",    2145380]
  ["長寛",    2145967]
  ["永万",    2146769]
  ["仁安",    2147205]
  ["嘉応",    2148161]
  ["承安",    2148912]
  ["安元",    2150454]
  ["治承",    2151198]
  ["養和",    2152655]
  ["寿永",    2152963]
  ["元暦",    2153661]
  ["文治",    2154131]
  ["建久",    2155841]
  ["正治",    2159135]
  ["建仁",    2159801]
  ["元久",    2160901]
  ["建永",    2161705]
  ["承元",    2162234]
  ["建暦",    2163488]
  ["建保",    2164489]
  ["承久",    2166444]
  ["貞応",    2167538]
  ["元仁",    2168489]
  ["嘉禄",    2168637]
  ["安貞",    2169602]
  ["寛喜",    2170040]
  ["貞永",    2171159]
  ["天福",    2171556]
  ["文暦",    2172107]
  ["嘉禎",    2172446]
  ["暦仁",    2173601]
  ["延応",    2173674]
  ["仁治",    2174185]
  ["寛元",    2175140]
  ["宝治",    2176619]
  ["建長",    2177377]
  ["康元",    2180109]
  ["正嘉",    2180267]
  ["正元",    2181017]
  ["文応",    2181417]
  ["弘長",    2181719]
  ["文永",    2182820]
  ["建治",    2186893]
  ["弘安",    2187929]
  ["正応",    2191649]
  ["永仁",    2193575]
  ["正安",    2195662]
  ["乾元",    2196957]
  ["嘉元",    2197237]
  ["徳治",    2198457]
  ["延慶",    2199131]
  ["応長",    2200037]
  ["正和",    2200383]
  ["文保",    2202167]
  ["元応",    2202960]
  ["元亨",    2203634]
  ["正中",    2205008]
  ["嘉暦",    2205527]
  ["元徳",    2206740]
  ["元弘",    2207459]
  ["正慶",    2207714]
  ["建武",    2208365]
  ["延元",    2209133]
  ["興国",    2210638]
  ["正平",    2213069]
  ["建徳",    2221678]
  ["文中",    2222302]
  ["天授",    2223453]
  ["弘和",    2225533]
  ["元中",    2226702]
  ["暦応",    2210046]
  ["康永",    2211375]
  ["貞和",    2212638]
  ["観応",    2214239]
  ["文和",    2215184]
  ["延文",    2216456]
  ["康安",    2218287]
  ["貞治",    2218812]
  ["応安",    2220786]
  ["永和",    2223364]
  ["康暦",    2224836]
  ["永徳",    2225547]
  ["至徳",    2226642]
  ["嘉慶",    2227937]
  ["康応",    2228456]
  ["明徳",    2228857]
  ["応永",    2230430]
  ["正長",    2242796]
  ["永享",    2243276]
  ["嘉吉",    2247452]
  ["文安",    2248532]
  ["宝徳",    2250533]
  ["享徳",    2251623]
  ["康正",    2252745]
  ["長禄",    2253516]
  ["寛正",    2254720]
  ["文正",    2256587]
  ["応仁",    2256978]
  ["文明",    2257769]
  ["長享",    2264405]
  ["延徳",    2265174]
  ["明応",    2266235]
  ["文亀",    2269375]
  ["永正",    2270469]
  ["大永",    2276869]
  ["享禄",    2279406]
  ["天文",    2280862]
  ["弘治",    2289332]
  ["永禄",    2290194]
  ["元亀",    2294647]
  ["天正",    2295833]
  ["文禄",    2302901]
  ["慶長",    2304337]
  ["元和",    2311174]
  ["寛永",    2314321]
  ["正保",    2321897]
  ["慶安",    2323077]
  ["承応",    2324734]
  ["明暦",    2325674]
  ["万治",    2326865]
  ["寛文",    2327871]
  ["延宝",    2332414]
  ["天和",    2335346]
  ["貞享",    2336224]
  ["元禄",    2337886]
  ["宝永",    2343539]
  ["正徳",    2346151]
  ["享保",    2348037]
  ["元文",    2355279]
  ["寛保",    2357049]
  ["延享",    2358136]
  ["寛延",    2359721]
  ["宝暦",    2360947]
  ["明和",    2365529]
  ["安永",    2368614]
  ["天明",    2371672]
  ["寛政",    2374529]
  ["享和",    2378939]
  ["文化",    2380038]
  ["文政",    2385216]
  ["天保",    2389841]
  ["弘化",    2394941]
  ["嘉永",    2396119]
  ["安政",    2398599]
  ["万延",    2400509]
  ["文久",    2400864]
  ["元治",    2401958]
  ["慶応",    2402358]
  ["明治",    2403357]
  ["大正",    2419614]
  ["昭和",    2424875]
  ["平成",    2447535]
  ["令和",    2458605]
]


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


moon_zero   = to_tempo_bare( Mars.calc.msec.moon,   Mars.calc.zero.moon,   new Date("2013-1-1") - 0 ).last_at
season_zero = to_tempo_bare( Mars.calc.msec.season, Mars.calc.zero.season, new Date("2013-1-1") - 0 ).last_at
list = []
for i in [0.. to_msec("20y") / Mars.calc.msec.moon]
  msec = moon_zero + i * Mars.calc.msec.moon
  { last_at, next_at } = to_tempo_bare Mars.calc.msec.day, msec
  list.push last_at - 1
  list.push last_at
  list.push next_at - 1
  list.push next_at
for i in [0.. to_msec("20y") / Mars.calc.msec.season]
  msec = season_zero + i * Mars.calc.msec.season
  { last_at, next_at } = to_tempo_bare Mars.calc.msec.day, msec
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

describe "JD", =>
  test '元号', =>
    list =
      for [title, jd] in ERAS
        JSON.stringify [
          title
          jd * to_msec("1d") + g.calc.zero.jd
        ]
    return
  return

describe "火星", =>
  return

  test '太陽の動き', =>
    dst = []
    for msec in mars_msecs
      dst.push to_graph Mars, msec
    expect dst
    .toMatchSnapshot()
    return

  test '二十四節季と月相', =>
    dst = []
    for msec in mars_msecs
      { graph } = Mars.to_tempos msec
      dst.push "#{graph} #{ Mars.format msec, "\t yMd E Hm", { locale } } #{ format msec, "\t yyyy-MM-dd EEE HH:mm", { locale } }"
    expect dst
    .toMatchSnapshot()
    return
  return


