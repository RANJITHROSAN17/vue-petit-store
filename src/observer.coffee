_ = require 'lodash'


intersectionBase = (option)->
  observer =
    if IntersectionObserver?
      new IntersectionObserver (doms)->
        doms.forEach (o)->
          o.target._cb_intersection
            is_hit: o.isIntersecting
            ratio: o.intersectionRatio
            cross: o.intersectionRect
            bound: o.boundingClientRect
            root:  o.rootBounds

      , option
    else
      observe: ->
      unobserve: ->
      disconnect: ->

  (id)->
    default_id = "#{id}_default"

    bind: (el, binding, { context })->
      vm = context
      vm[default_id] = _.get vm, id
      _.set vm, id, null
      # vm[type_id] = types[vm[default_id].constructor]

    inserted: (el, binding, { context })->
      cb = (o)->
        _.set @, id, 
          if o.is_hit
            @[default_id]
          else
            null
      el._cb_intersection = cb.bind context
      observer.observe el

    unbind: (el)->
      observer.unobserve el
      # observer.disconnect

resize_observer =
  if ResizeObserver?
    new ResizeObserver (doms)->
      doms.forEach (o)->
        { width, height } = o.contentRect
        width  = parseInt width
        height = parseInt height
        o.target._cb_resize { width, height }
  else
    observe: ->
    unobserve: ->
    disconnect: ->

module.exports =
  resize: (id)->
    default_id = "#{id}_default"
    type_id = "#{id}_type"
    observer = resize_observer

    bind: (el, binding, { context })->
      vm = context
      vm[default_id] = _.get vm, id
      # vm[type_id] = types[vm[default_id].constructor]

    inserted: (el, binding, { context })->
      cb = (size)->
        _.set @, id, size
      el._cb_resize = cb.bind context
      observer.observe el

    unbind: (el)->
      observer.unobserve el
      observer.disconnect el

  on_horizon: intersectionBase
    root: null
    rootMargin: '-50% 0% -50% 0%'
    threshold: [0]

  on_peek: intersectionBase
    root: null
    rootMargin: '25%'
    threshold: [0]

  on_appear: intersectionBase
    root: null
    rootMargin: '0%'
    threshold: [0.5]
