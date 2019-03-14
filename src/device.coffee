motion_request = ->
  return unless window?
  window.addEventListener "deviceorientation", ({ alpha, beta, gamma, absolute })->
    gyro.alpha = round alpha
    gyro.beta = round beta
    gyro.gamma = round gamma

  window.addEventListener "devicemotion", ({ interval, acceleration, accelerationIncludingGravity, rotationRate })->
    interval
    { x, y, z } = acceleration
    accel.x = round x
    accel.y = round y
    accel.z = round z

    { x, y, z } = accelerationIncludingGravity
    accel_with_gravity.x = round x
    accel_with_gravity.y = round y
    accel_with_gravity.z = round z

    gravity.x = round x - acceleration.x
    gravity.y = round y - acceleration.y
    gravity.z = round z - acceleration.z

    { alpha, beta, gamma } = rotationRate
    rotate.alpha = round alpha
    rotate.beta  = round beta
    rotate.gamma = round gamma

  motion_request = ->

geo_request = ->
  return unless navigator?.geolocation?
  navigator.geolocation.watchPosition ({ coords, timestamp })->
    { accuracy, altitudeAccuracy, latitude, longitude, altitude, heading, speed } = coords
    geo.latitude = latitude
    geo.longitude = longitude
    geo.altitude = altitude
    geo.heading = heading
    geo.speed = speed

  , ({ code })->
    console.log "watchPosition error = #{code}"
  ,
    enableHighAccuracy: true
    timeout:    10 * 1000
    maximumAge: 60 * 1000

  geo_request = ->

round = (val)->
  m.pow * Math.round val

gyro =
  alpha: 0 # z-axis
  beta:  0 # x-axis
  gamma: 0 # y-axis

accel =
  x: 0
  y: 0
  z: 0

gravity =
  x: 0
  y: 0
  z: 0

accel_with_gravity =
  x: 0
  y: 0
  z: 0

rotate =
  alpha: 0
  beta:  0
  gamma: 0

geo =
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



module.exports = m =
  device: ({ pow })->
    m.pow = pow

  geo: ->
    data: ->
      { geo }
    mounted: ->
      geo_request()

  accel: ->
    data: ->
      { accel, gravity, accel_with_gravity }

    created: ->
      motion_request()

  rotate: ->
    data: ->
      { gyro, rotate }

    created: ->
      motion_request()

  scroll: ->
    data: ->
      { scroll }

    created: ->
      return unless window?
      @scroll_poll()

    methods:
      scroll_poll: ->
        @scroll.top = scrollY
        @scroll.left = scrollX
        @scroll.width = innerWidth
        @scroll.height = innerHeight
        { height, top, left, width } = @scroll

        @scroll.horizon = parseInt height / 2
        @scroll.center = parseInt top + height / 2
        @scroll.bottom = parseInt top + height
        @scroll.right = parseInt left + width

        requestAnimationFrame @scroll_poll

