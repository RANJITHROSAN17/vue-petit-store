Mem = require "memory-orm"

if window?
  firebase = require "firebase/app"
  require "firebase/firestore"

firestore = ->
  store = firebase.firestore()
  store.settings {}
  store

copy_to_str = (key)->(...args)->
  @str += " #{key}:"
  for arg in args
    @str += arg
    @str += ":"
  @ref = @ref[key] ...args
  @

class FirestoreQueryProxy
  constructor: (@str, @ref)->
  orderBy: copy_to_str "orderBy"
  limit:   copy_to_str "limit"
  where:   copy_to_str "where"

joinSnapshot = (target, shot)->
  eject = ->
  (gate)->
    eject()
    eject =
      if gate && @[target]
        console.log "join", gate
        @[target].onSnapshot shot.bind(@), (err)->
          console.error err
      else
        ->

firestore_base = (id, path, querys, { del, add, snap, shot })->
  default_id = "#{id}_default"

  join_id = "#{id}_join"
  snap_id = "#{id}_snap"
  path_id = "#{id}_path"

  add_id  = "#{id}_add"
  del_id  = "#{id}_del"

  joins = []
  watch = {}
  computed =
    _firestore: firestore
    [path_id]: path
    [snap_id]: ->
      if @[path_id]
        snap.call @, @[path_id]

  if querys?.length
    querys.forEach (query, idx)->
      query_id = "#{id}_query_#{idx}_query"
      ref_id   = "#{id}_query_#{idx}_ref"
      str_id   = "#{id}_query_#{idx}_str"

      computed[ref_id] = ->
        return unless @[path_id]
        query.call @, new FirestoreQueryProxy @[path_id], @[snap_id]

      computed[str_id] = ->
        @[ref_id]?.str

      computed[query_id] = ->
        if @[str_id]
          @[ref_id].ref

      join = joinSnapshot query_id, shot
      joins.push [join, str_id]
      watch[str_id] = join

  else
    join = joinSnapshot snap_id, shot
    joins.push [join, path_id]
    watch[path_id] = join

  beforeDestroy: ->
    for [join, join_id] in joins
      join.call @, undefined

  mounted: ->
    @[default_id] = @[id]
    for [join, join_id] in joins
      join.call @, @[join_id]

  methods:
    [add_id]: add
    [del_id]: del

  computed: computed
  watch:    watch


module.exports = m =
  firestore_models: (id, path, ...querys)->
    snap_id = "#{id}_snap"
    set_key = id[..-2]
    firestore_base id, path, querys,
      del: (_id)->
        return unless _id
        @[snap_id]?.doc(_id).delete()
      add: (doc)->
        { _id } = doc
        return unless _id
        @[snap_id]?.doc(_id).set doc,
          merge: true
      snap: (path)->
        @_firestore.collection path
      shot: (qs)->
        qs.docChanges().forEach ({ newIndex, oldIndex, type, doc })=>
          switch type
            when 'added', 'modified'
              Mem.Set[set_key].add doc.data()
            when 'removed'
              Mem.Set[set_key].remove doc.id

  firestore_model: (id, path)->
    snap_id = "#{id}_snap"
    set_key = id
    firestore_base id, path, null,
      del: ->
        @[snap_id]?.delete()
      add: (doc)->
        @[snap_id]?.set doc,
          merge: true
      snap: (path)->
        @_firestore.doc path
      shot: (doc)->
        if o = doc.data()
          Mem.Set[set_key].add o
        else
          Mem.Set[set_key].remove doc.id

  firestore_collection: (id, path, ...querys)->
    snap_id = "#{id}_snap"
    firestore_base id, path, querys,
      del: (_id)->
        return unless _id
        @[snap_id]?.doc(_id).delete()
      add: (doc)->
        { _id } = doc
        return unless _id
        @[snap_id]?.doc(_id).set doc,
          merge: true
      snap: (path)->
        @_firestore.collection path
      shot: (qs)->
        qs.docChanges().forEach ({ newIndex, oldIndex, type, doc })=>
          switch type
            when 'added', 'modified'
              @[id][doc.id] = doc.data()
            when 'removed'
              delete @[id][doc.id]

  firestore_doc: (id, path)->
    snap_id = "#{id}_snap"
    default_id = "#{id}_default"
    firestore_base id, path, null,
      del: ->
        @[snap_id]?.delete()
      add: (doc)->
        @[snap_id]?.set doc,
          merge: true
      snap: (path)->
        @_firestore.doc path
      shot: (doc)->
        @[id] =
          if doc.exists
            doc.data()
          else
            @[default_id]
