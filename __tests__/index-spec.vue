<template lang="pug">
div
  span {{ a }}
  span {{ b }}
</template>

<script lang="coffee">
{ replaceState, pushState, sessionStorage, localStorage, cookie,
  firestore_models, firestore_model, firestore_collection, firestore_doc,
  path_by, vuex_read, vuex
} = require "../lib/index.min"

module.exports =
  mixins: [
    vuex      "index", ["a"]
    vuex_read "index", ["b"]
  ]
</script>

