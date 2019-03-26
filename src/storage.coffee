_ = require 'lodash'
Cookie = require 'tiny-cookie'
{ types, relative_to } = require "./struct"

try
  test = '__vue-localstorage-test__'

  Cookie.set test, test, expres: '1M'
  Cookie.remove test

  window.localStorage.setItem test, test
  window.localStorage.removeItem test

  window.sessionStorage.setItem test, test
  window.sessionStorage.removeItem test

  history || throw new Error "can't use history API."
catch e
  console.warn 'Local storage not supported by this browser'


module.exports = m =
  sessionStorage: (id)->
    default_id = "#{id}_default"
    type_id = "#{id}_type"

    created: ->
      @[default_id] = _.get @, id
      @[type_id] = types[@[default_id].constructor]

    mounted: ->
      newVal = window.sessionStorage.getItem id
      if newVal?
        @[id] = @[type_id].by_str newVal

    watch:
      [id]: ( newVal )->
        if newVal?
          s = @[type_id].to_str newVal
          window.sessionStorage.setItem id, s
        else
          window.sessionStorage.removeItem id

  localStorage: (id)->
    default_id = "#{id}_default"
    handle_id = "#{id}_handle"
    type_id = "#{id}_type"

    created: ->
      @[default_id] = _.get @, id
      @[type_id] = types[@[default_id].constructor]

    mounted: ->
      newVal = window.localStorage.getItem id
      if newVal?
        @[id] = @[type_id].by_str newVal

      @[handle_id] = ({ key, newValue })=>
        if key == id
          @[id] = @[type_id].by_str newValue
      window.addEventListener "storage", @[handle_id]
    
    beforeDestroy: ->
      window.removeEventListener "storage", @[handle_id]

    watch:
      [id]: ( newVal )->
        if newVal?
          s = @[type_id].to_str newVal
          window.localStorage.setItem id, s
        else
          window.localStorage.removeItem id

  cookie: (id, options = { expires: '1M' })->
    default_id = "#{id}_default"
    type_id = "#{id}_type"

    created: ->
      @[default_id] = _.get @, id
      @[type_id] = types[@[default_id].constructor]

    mounted: ->
      newVal = Cookie.get id
      if newVal?
        @[id] = @[type_id].by_str newVal

    watch:
      [id]: ( newVal )->
        if newVal?
          s = @[type_id].to_str newVal
          Cookie.set id, s, options
        else
          Cookie.remove id

