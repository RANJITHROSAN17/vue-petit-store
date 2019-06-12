_ = require 'lodash'
Cookie = require 'tiny-cookie'
{ types, relative_to } = require "./struct"

$session_storage = {}
$local_storage = {}
$cookie_storage = {}

capture = (s, type, _default)->
  if s?
    type.by_str s
  else
    _default

module.exports = m =
  sessionStorage: (id)->
    global_id = "$data.$session_storage.#{id}"
    default_id = "#{id}_default"
    type_id = "#{id}_type"

    unless _.has $session_storage, id
      _.set $session_storage, id, null

    data: -> { $session_storage }

    created: ->
      @[default_id] = _.get @, id
      @[type_id] = types[@[default_id].constructor]

    mounted: ->
      s = window.sessionStorage.getItem id
      val = capture s, @[type_id], @[default_id]
      _.set @, id, val
      _.set $session_storage, id, val

    watch:
      [global_id]: ( val )->
        _.set @, id, val

      [id]: ( val )->
        _.set $session_storage, id, val
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

    unless _.has $local_storage, id
      _.set $local_storage, id, null

    data: -> { $local_storage }

    created: ->
      @[default_id] = _.get @, id
      @[type_id] = types[@[default_id].constructor]

    mounted: ->
      s = window.localStorage.getItem id
      val = capture s, @[type_id], @[default_id]
      _.set @, id, val
      _.set $local_storage, id, val
      @[handle_id] = ({ key, newValue })=>
        if key == id
          val = capture newValue, @[type_id], @[default_id]
          _.set @, id, val
          _.set $local_storage, id, val

      window.addEventListener "storage", @[handle_id]
    
    beforeDestroy: ->
      window.removeEventListener "storage", @[handle_id]

    watch:
      [global_id]: ( val )->
        _.set @, id, val

      [id]: ( val )->
        _.set $local_storage, id, val
        if val?
          s = @[type_id].to_str val
          window.localStorage.setItem id, s
        else
          window.localStorage.removeItem id

  cookie: (id, options = { expires: '1M' })->
    global_id = "$data.$cookie_storage.#{id}"
    default_id = "#{id}_default"
    type_id = "#{id}_type"

    unless _.has $cookie_storage, id
      _.set $cookie_storage, id, null

    data: -> { $cookie_storage }

    created: ->
      @[default_id] = _.get @, id
      @[type_id] = types[@[default_id].constructor]

    mounted: ->
      s = Cookie.get id
      val = capture s, @[type_id], @[default_id]
      _.set @, id, val
      _.set $cookie_storage, id, val

    watch:
      [global_id]: ( val )->
        _.set @, id, val

      [id]: ( val )->
        _.set $cookie_storage, id, val
        if val?
          s = @[type_id].to_str val
          Cookie.set id, s, options
        else
          Cookie.remove id

