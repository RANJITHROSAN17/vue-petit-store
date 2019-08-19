geo_to_s = (n, mark, minus)->
  n1 = parseInt n 
  n2 = parseInt n *       60 % 60
  n3 = parseInt n *     3600 % 60
  n4 = parseInt n *   216000 % 60
  n5 = parseInt n * 12960000 % 60
  mark = minus if n < 0
  """#{n1}°#{n2}′#{n3}″#{n4}‴#{n5}⁗#{mark}"""

mks_to_s = (n, mark)->
  n1 = parseInt n
  n2 = parseInt n * 100 % 100
  """#{n1}#{mark}#{n2}c#{mark}"""

threshold_to_s = (newVal, margin, keep, lo, l1, l2, l3)->
  switch
    when newVal < -margin
      l1
    when margin < newVal
      l3
    when lo == l1 && newVal < -keep
      l1
    when lo == l3 && keep < newVal
      l3
    else
      l2

xyz = (newVal, oldVal)->
  { x, y, z } = newVal
  { margin, keep } = m
  margin *= 10
  keep   *= 10
  oldVal.label_x = lx = threshold_to_s x, margin, keep, oldVal.label_x, "右", "", "左"
  oldVal.label_y = ly = threshold_to_s y, margin, keep, oldVal.label_y, "上", "", "下"
  oldVal.label_z = lz = threshold_to_s z, margin, keep, oldVal.label_z, "表", "", "裏"
  oldVal.label = """#{lx}#{ly}#{lz}"""

  oldVal.x = x
  oldVal.y = y
  oldVal.z = z

abg = (newVal, oldVal)->
  { alpha, beta, gamma } = newVal
  { margin, keep } = m
  margin *= 360
  keep   *= 360
  oldVal.label_alpha = la = threshold_to_s alpha, margin, keep, oldVal.label_alpha, "押下", "", "引上"
  oldVal.label_beta  = lb = threshold_to_s beta,  margin, keep, oldVal.label_beta,  "左巻", "", "右巻"
  oldVal.label_gamma = lg = threshold_to_s gamma, margin, keep, oldVal.label_gamma, "右折", "", "左折"
  oldVal.label = """#{la}#{lb}#{lg}"""

  oldVal.alpha = alpha
  oldVal.beta  = beta
  oldVal.gamma = gamma

xyz_new = ->
  x: 0
  y: 0
  z: 0
  label: ""
  label_x: ""
  label_y: ""
  label_z: ""

abg_new = ->
  alpha: 0
  beta:  0
  gamma: 0
  absolute: 0
  label: ""
  label_alpha: ""
  label_beta:  ""
  label_gamma: ""

accel = xyz_new()
gravity = xyz_new()
accel_with_gravity = xyz_new()

gyro = abg_new()
rotate = abg_new()

geo =
  label: ""
  latitude:  0
  longitude: 0
  altitude:  0
  heading:   0
  speed:     0

scroll =
  top:    0
  center: 0
  bottom: 0

  left:   0
  right:  0

  horizon: 0
  height:  0
  width:   0

  size:         0
  aspect_ratio: 1
  is_square:     true
  is_oblong:    false
  is_horizontal: true
  is_vertical:  false

deviceorientation =
  count: 0
  call: ({ alpha, beta, gamma, absolute })->
    gyro.alpha = alpha
    gyro.beta  = beta
    gyro.gamma = gamma
    gyro.absolute = absolute

  with: (o)->
    Object.assign o,
      mounted: =>
        return unless window?
        return if @count++
        window.addEventListener "deviceorientation", @call

      beforeDestroy: =>
        return if --@count
        window.removeEventListener "deviceorientation", @call

devicemotion =
  count: 0
  call: ({ interval, acceleration, accelerationIncludingGravity, rotationRate })->
    calc_gravity =
      x: accelerationIncludingGravity.x - acceleration.x
      y: accelerationIncludingGravity.y - acceleration.y
      z: accelerationIncludingGravity.z - acceleration.z
    xyz acceleration,                 accel
    xyz accelerationIncludingGravity, accel_with_gravity
    xyz calc_gravity,                 gravity

    abg rotationRate, rotate

  with: (o)->
    Object.assign o,
      mounted: =>
        return unless window?
        return if @count++
        window.addEventListener "devicemotion", @call

      beforeDestroy: =>
        return if --@count
        window.removeEventListener "devicemotion", @call

geolocation =
  watch_id: null
  count: 0
  call: ({ coords, timestamp })->
    { accuracy, altitudeAccuracy, latitude, longitude, altitude, heading, speed } = coords
    altitude ?= 0

    geo.label = """#{geo_to_s(longitude,'N','S')} #{geo_to_s(latitude,'E','W')} #{mks_to_s(altitude,'m')}"""
    geo.longitude = longitude
    geo.latitude = latitude
    geo.altitude = altitude
    geo.heading = heading
    geo.speed = speed

  with: (o)->
    Object.assign o,
      mounted: =>
        return unless navigator?.geolocation?
        return if @count++
        @watch_id = navigator.geolocation.watchPosition @call, ({ code })->
          console.log "watchPosition error = #{code}"
        ,
          enableHighAccuracy: true
          maximumAge: 60 * 1000
          timeout:    10 * 1000
      beforeDestroy: =>
        return if --@count
        navigator.geolocation.clearWatch @watch_id

scroll_poll =
  count: 0
  call: ->
    scroll.top = parseInt scrollY
    scroll.left = parseInt scrollX
    scroll.width = parseInt innerWidth
    scroll.height = parseInt innerHeight
    { height, top, left, width } = scroll

    if width < height
      scroll.size = width
      scroll.aspect_ratio = height / width
      scroll.is_vertical = true
      scroll.is_horizontal = false
    else
      scroll.size = height
      scroll.aspect_ratio = width / height
      scroll.is_vertical = false
      scroll.is_horizontal = true
    scroll.is_square = !( scroll.is_oblong = 1.35 < scroll.aspect_ratio )

    scroll.horizon = height >> 1
    scroll.center = top + (height >> 1)
    scroll.bottom = top + height
    scroll.right = left + width

    requestAnimationFrame scroll_poll.call

  with: (o)->
    Object.assign o,
      mounted: =>
        return unless window?
        return if @count++
        @call()

      beforeDestroy: =>


module.exports = m =
  margin: 0.4
  keep:   0.1
  device: ({ margin, keep })->
    m.margin = margin
    m.keep   = keep

  geo: ->
    geolocation.with
      data: ->
        { geo }

  gyro: ->
    deviceorientation.with
      data: ->
        { gyro }

  accel: ->
    devicemotion.with
      data: ->
        { accel, gravity, accel_with_gravity }

  rotate: ->
    devicemotion.with
      data: ->
        { rotate }

  scroll: ->
    scroll_poll.with
      data: ->
        { scroll }

      methods:
        scroll_to: ({ query, mode })->
          return unless el = document?.querySelector query
          return unless { height, top } = el.getBoundingClientRect()
          switch mode
            when 'center'
              top += (height >> 1) - scroll.horizon
            when 'bottom'
              top +=  height

          console.log " go to #{query}(#{mode}) as #{top}px"
          window.scrollBy 0, top
