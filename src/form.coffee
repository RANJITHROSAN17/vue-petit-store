
chk = ( all, local, msg, b )->
  all.push msg
  if b
    local.push msg

module.exports =
  error: (id, cb)->
    local_id = "#{id}_local"
    all_id = "#{id}_all"
    is_id = "is_#{id}"

    props: [id]

    data: ->
      [all_id]: []

    computed:
      [local_id]: ->
        cb.call @, chk.bind null, @[all_id] = [], local = []
        local

    watch:
      [local_id]: (local)->
        ary = _.difference @[id], @[all_id]
        ary = _.union ary, local
        @$emit "update:#{id}", ary

  form: (id, cb, origin)->
    origin_id = "#{id}_origin"
    base_id = "#{id}_base"
    init_id = "#{id}_init"
    is_edit_id = "is_#{id}_edit"
    keys = []

    data: ->
      form = cb.call @
      keys = Object.keys form
      base = {}
      for key in keys
        form[key] = base[key] = null

      [id]: form
      [base_id]: base

    computed:
      [origin_id]: origin
      [is_edit_id]: ->
        ! _.isEqual @[id], @[base_id]

    methods:
      [init_id]: (src)->
        for key in keys
          @[id][key] = @[base_id][key] = src[key]

    watch:
      [origin_id]: (o)->
        @[init_id] o
