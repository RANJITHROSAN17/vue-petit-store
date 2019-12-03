{ to_timer, to_msec, to_sec, to_relative_time_distance } = require "../lib/index.min"

describe "to_relative_time_distance", =>
  test 'snapshot edge in 52bit', =>
    expect to_relative_time_distance -0xfffffffffffff
    .toMatchSnapshot()
    expect to_relative_time_distance  0xfffffffffffff
    .toMatchSnapshot()
    return
  test 'snapshot edge out 52bit', =>
    expect to_relative_time_distance -0x10000000000000
    .toMatchSnapshot()
    expect to_relative_time_distance  0x10000000000000
    .toMatchSnapshot()
    return

  test 'snapshot distance', =>
    expect to_relative_time_distance -to_msec "1秒"
    .toMatchSnapshot()
    expect to_relative_time_distance -to_msec "59分59秒"
    .toMatchSnapshot()
    expect to_relative_time_distance -to_msec "23時間59分59秒"
    .toMatchSnapshot()
    expect to_relative_time_distance -to_msec "6日23時間59分59秒"
    .toMatchSnapshot()
    expect to_relative_time_distance -to_msec "4週1日23時間59分59秒"
    .toMatchSnapshot()
    expect to_relative_time_distance -to_msec "52週1日5時48分45秒"
    .toMatchSnapshot()

    expect to_relative_time_distance to_msec "1秒"
    .toMatchSnapshot()
    expect to_relative_time_distance to_msec "1分"
    .toMatchSnapshot()
    expect to_relative_time_distance to_msec "1h"
    .toMatchSnapshot()
    expect to_relative_time_distance to_msec "1日"
    .toMatchSnapshot()
    expect to_relative_time_distance to_msec "1週間"
    .toMatchSnapshot()
    expect to_relative_time_distance to_msec "1年"
    .toMatchSnapshot()
    return

  test 'snapshot 半', =>
    expect to_timer to_msec "1秒半"
    .toMatchSnapshot()
    expect to_timer to_msec "1分半"
    .toMatchSnapshot()
    expect to_timer to_msec "1時間半"
    .toMatchSnapshot()
    expect to_timer to_msec "1日半"
    .toMatchSnapshot()
    expect to_timer to_msec "1年半"
    .toMatchSnapshot()
    return
  return

describe "to_timer and to_msec", =>
  test 'value eng', =>
    expect to_timer to_msec "1秒"
    .toMatchSnapshot()
    expect to_timer to_msec "1分1秒"
    .toMatchSnapshot()
    expect to_timer to_msec "1時1分1秒"
    .toMatchSnapshot()
    expect to_timer to_msec "1日1時1分1秒"
    .toMatchSnapshot()
    expect to_timer to_msec "1週1日1時1分1秒"
    .toMatchSnapshot()
    expect to_timer to_msec "1年1週1日1時1分1秒"
    .toMatchSnapshot()
    return
  test 'value jpn', =>
    expect to_timer to_msec("1秒"), 0
    .toMatchSnapshot()
    expect to_timer to_msec("1分1秒"), 0
    .toMatchSnapshot()
    expect to_timer to_msec("1時1分1秒"), 0
    .toMatchSnapshot()
    expect to_timer to_msec("1日1時1分1秒"), 0
    .toMatchSnapshot()
    expect to_timer to_msec("1週1日1時1分1秒"), 0
    .toMatchSnapshot()
    expect to_timer to_msec("1年1週1日1時1分1秒"), 0
    .toMatchSnapshot()
    expect to_timer to_msec("1年") - 1, 0
    .toMatchSnapshot()
    return
  return