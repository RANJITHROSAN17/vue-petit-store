_ = require 'lodash'
Cookie = require 'tiny-cookie'
{ types, relative_to } = require "./struct"

$session_storage = {}
$local_storage = {}
$cookie_storage = {}

module.exports = m =
  sessionStorage: (id)->
    global_id = "$data.$session_storage.#{id}"
    default_id = "#{id}_default"
    type_id = "#{id}_type"

    _.set $session_storage, id, null

    data: -> { $session_storage }

    created: ->
      @[default_id] = _.get @, id
      @[type_id] = types[@[default_id].constructor]

    mounted: ->
      s = window.sessionStorage.getItem id
      if s?
        val = @[type_id].by_str s
        _.set @, id, val
        @$set @$data.$session_storage, id, val

    watch:
      [global_id]: ( val )->
        _.set @, id, val

      [id]: ( val )->
        @$set @$data.$session_storage, id, val
        if val?
          s = @[type_id].to_str val
          window.sessionStorage.setItem id, s
        else
          window.sessionStorage.removeItem id

  localStorage: (id)->
    global_id = "$data.$local_storage.#{id}"
    default_id = "#{id}_default"
    handle_id = "#{id}_handle"
    type_id = "#{id}_type"

    _.set $local_storage, id, null

    data: -> { $local_storage }

    created: ->
      @[default_id] = _.get @, id
      @[type_id] = types[@[default_id].constructor]

    mounted: ->
      s = window.localStorage.getItem id
      if s?
        val = @[type_id].by_str s
        _.set @, id, val
        @$set @$data.$local_storage, id, val
      @[handle_id] = ({ key, newValue })=>
        if key == id
          val = @[type_id].by_str newValue
          _.set @, id, val
          @$set @$data.$local_storage, id, val

      window.addEventListener "storage", @[handle_id]
    
    beforeDestroy: ->
      window.removeEventListener "storage", @[handle_id]

    watch:
      [global_id]: ( val )->
        _.set @, id, val

      [id]: ( val )->
        @$set @$data.$local_storage, id, val
        if val?
          s = @[type_id].to_str val
          window.localStorage.setItem id, s
        else
          window.localStorage.removeItem id

  cookie: (id, options = { expires: '1M' })->
    global_id = "$data.$cookie_storage.#{id}"
    default_id = "#{id}_default"
    type_id = "#{id}_type"

    _.set $cookie_storage, id, null

    data: -> { $cookie_storage }

    created: ->
      @[default_id] = _.get @, id
      @[type_id] = types[@[default_id].constructor]

    mounted: ->
      s = Cookie.get id
      if s?
        val = @[type_id].by_str s
        _.set @, id, val
        @$set @$data.$cookie_storage, id, val

    watch:
      [global_id]: ( val )->
        _.set @, id, val

      [id]: ( val )->
        @$set @$data.$cookie_storage, id, val
        if val?
          s = @[type_id].to_str val
          Cookie.set id, s, options
        else
          Cookie.remove id

