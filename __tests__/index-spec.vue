<template lang="pug">
div
  span {{ a }}
  span {{ b }}
  span {{ c }}
  span {{ d }}
  span {{ e }}
  span {{ f }}
  span {{ g }}
  span {{ h }}
  span {{ i }}
  span {{ j }}
</template>

<script lang="coffee">
{ replaceState, pushState, sessionStorage, localStorage, cookie,
  firestore_models, firestore_model, firestore_collection, firestore_doc,
  vuex_read, vuex,
} = require "../lib/index.min"

module.exports =
  mixins: [
    vuex      "index", ["a"]
    vuex_read "index", ["b"]
    pushState "c"
    pushState "d"
    replaceState "e"
    replaceState "f"
    sessionStorage "g"
    localStorage "h"
    cookie "i"
  ]

  data: ->
    c: "c"
    d: "d"
    e: "e"
    f: "f"
    g: "g"
    h: "h"
    i: "i"
    j: "j"

  methods:
    swap: ->
      [@c, @d, @e, @f] = [@f, @e, @d, @c]
      [@g, @h, @i, @j] = [@j, @i, @h, @g]

</script>

