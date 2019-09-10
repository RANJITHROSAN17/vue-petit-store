_ = require 'lodash'

zero = [null, undefined, "", NaN]

simple_route = (o)->
  for key, val of o.query
    if zero.includes val
      delete o.query[key]
  o

relative_to = ({ name, params, query, hash }, o, is_replace)->
  unless is_replace
    params = _.cloneDeep params
    query  = _.cloneDeep query
  to = { name, params, query, hash }
  for key, val of o
    tgt =
      if params.hasOwnProperty key
        params
      else
        query
    tgt[key] = val
  simple_route to

to_String = (nil)-> (u)->
  if zero.includes u
    nil
  else
    String u

to_Number = (u)->
  if zero.includes u
    NaN
  else
    Number u

to_Array = (u)->
  if zero.includes u
    []
  else
    if u instanceof Array then u else Array u

module.exports = {
  simple_route
  relative_to
  types:
    [Number]:
      to_str: to_String ""
      by_str: to_Number
      by_url: to_Number
    [String]:
      to_str: to_String ""
      by_str: to_String undefined
      by_url: to_String ""
    [Array]:
      to_str: (o)-> JSON.stringify(o) || []
      by_str: (o)-> JSON.parse(o) || []
      by_url: to_Array
    [Object]:
      to_str: (o)-> JSON.stringify(o) || {}
      by_str: (o)-> JSON.parse(o) || {}
}
