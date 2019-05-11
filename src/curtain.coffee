_ = require 'lodash'


module.exports =
  curtain: (id)->
    spots_id = "#{id}_spots"
    space_id = "#{id}_space"
    calc_id  = "#{id}_calc"
    left_id   = "#{id}_left"
    top_id    = "#{id}_top"
    right_id  = "#{id}_right"
    bottom_id = "#{id}_bottom"

    directives:
      [id]:
        bind: (el, binding, { context })->
          vm = context
          vm.$refs[id] ?= []
          vm.$refs[id].push el

    data: ->
      left = top = -Infinity
      right = bottom = Infinity
      [spots_id]: []
      [id]: { left, top, right, bottom }

    computed:
      [left_id]:   -> o.left   < @[id].left   for o in @[spots_id]
      [top_id]:    -> o.top    < @[id].top    for o in @[spots_id]
      [right_id]:  -> @[id].right  < o.right  for o in @[spots_id]
      [bottom_id]: -> @[id].bottom < o.bottom for o in @[spots_id]

      [space_id]: ->
        enter = =>
          @[calc_id]()
        leave = =>
          left = top = 0
          right = bottom = Infinity
          @[id] = { left, top, right, bottom }
        move = (e)=>
          left = right = e.pageX ? e.changedTouches?[0]?.pageX
          top = bottom = e.pageY ? e.changedTouches?[0]?.pageY
          @[id] = { left, top, right, bottom }

        scroll: enter
        touchenter: enter
        touchmove:  move
        touchleave: leave
        mouseenter: enter
        mousemove:  move
        mouseleave: leave

    methods:
      [calc_id]: ->
        return unless list = @$refs[id]
        @[spots_id] =
          for o in list
            if oo = o.getClientRects()?[0]
              { left, top, right, bottom } = oo
            else
              left = top = Infinity
              right = bottom = 0
            { left, top, right, bottom }

