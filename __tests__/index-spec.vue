<template lang="pug">
div
  span(v-col) {{ a }}
  span(v-col) {{ b }}
  span(v-col) {{ c }}
  span(v-col) {{ d }}
  span(v-col) {{ e }}
  span(v-col) {{ f }}
  span(v-col) {{ g }}
  span(v-col) {{ h }}
  span(v-col) {{ i }}
  span(v-col) {{ j }}
  span(v-col) {{ ary }}
</template>

<script lang="coffee">
{ replaceState, pushState, sessionStorage, localStorage, cookie,
  firestore_models, firestore_model, firestore_collection, firestore_doc,
  vuex_read, vuex, share

  curtain,
  resize,

  on_horizon, on_peek, on_appear,

  poll,

  geo, gyro, scroll, accel, rotate
} = require "../lib/index.min"

module.exports =
  mixins: [
    share "a"
    vuex_read "b", on: "index"
    pushState "c"
    pushState "d"
    replaceState "e"
    replaceState "f"
    sessionStorage "g"
    localStorage "h"
    cookie "i"
    pushState "ary"
    firestore_collection "items",
      -> "/test/book-1/items"
      (o)-> @name && o.where("name1", "==", @name)
      (o)-> @name && o.where("name2", "==", @name)
    poll -> []
    geo()
    gyro()
    accel()
    rotate()
    scroll()
    curtain "col"
  ]

  directives: 
    peek:    on_peek    'peek'
    appear:  on_appear  'appear'
    resize:  resize     'resize'
    horizon: on_horizon 'horizon'

  data: ->
    peek:    "test"
    appear:  "test"
    resize:  "test"
    horizon: "test"
    name: "test"
    items: {}
    c: "c"
    d: "d"
    e: "e"
    f: "f"
    g: "g"
    h: "h"
    i: "i"
    j: "j"
    ary: []

  methods:
    swap: ->
      [@c, @d, @e, @f] = [@f, @e, @d, @c]
      [@g, @h, @i, @j] = [@j, @i, @h, @g]

</script>

