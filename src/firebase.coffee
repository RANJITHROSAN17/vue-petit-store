Mem = require "memory-orm"

if window?
  firebase = require "firebase"

firestore = ->
  store = firebase.firestore()
  store.settings {}
  store

joinSnapshot = (target, shot)->
  eject = ->
  (gate)->
    eject()
    eject =
      if gate && @[target]
        console.log "join", gate
        @[target].onSnapshot shot.bind @
      else
        ->

firestore_base = (id, path, chk, query, { del, add, snap, shot })->
  default_id = "#{id}_default"

  query_id = "#{id}_query"
  snap_id  = "#{id}_snap"

  chk_id  = "#{id}_chk"
  path_id = "#{id}_path"

  join_id = "#{id}_join"
  add_id  = "#{id}_add"
  del_id  = "#{id}_del"

  [ snapshot, join_target ] =
    if chk && query
      [ chk_id, query_id ]
    else
      [ path_id, snap_id ]
  join = joinSnapshot join_target, shot

  data: ->
    step: Mem.State.step

  mounted: ->
    @[default_id] = @[id]
    @[join_id] @[snapshot]

  beforeDestroy: ->
    @[join_id] undefined

  methods:
    [join_id]: join
    [add_id]: add
    [del_id]: del

  computed:
    if chk && query
      _firestore: firestore

      [path_id]: path
      [snap_id]: ->
        if @[path_id]
          snap.call @, @[path_id]

      [chk_id]: chk
      [query_id]: ->
        if @[chk_id] && @[snap_id]
          query.call @, @[snap_id]
    else
      _firestore: firestore

      [path_id]: path
      [snap_id]: ->
        if @[path_id]
          snap.call @, @[path_id]

  watch:
    [snapshot]: join


module.exports = m =
  firestore_models: (id, path, chk, query)->
    snap_id = "#{id}_snap"
    set_key = id[..-2]
    firestore_base id, path, chk, query,
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
    firestore_base id, path, null, null,
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

  firestore_collection: (id, path, chk, query)->
    snap_id = "#{id}_snap"
    firestore_base id, path, chk, query,
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
    firestore_base id, path, null, null,
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
