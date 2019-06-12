_ = require 'lodash'

relative_to = ({ name, params, query, hash }, o, is_replace)->
  unless is_replace
    params = _.cloneDeep params
    query  = _.cloneDeep query
  to = { name, params, query, hash }
  for key, val of o
    if params[key]
      params[key] = val
    else
      query[key] = val
  to

to_String = (nil)-> (u)->
  switch u
    when null, undefined, "", NaN
      nil
    else
      String u

to_Number = (u)->
  switch u
    when null, undefined, "", NaN
      NaN
    else
      Number u

to_Array = (u)->
  switch u
    when null, undefined, "", NaN
      []
    else
      if u instanceof Array then u else Array u

module.exports = {
  relative_to
  types:
    [Number]:
      to_str: to_String ""
      by_str: to_Number
      by_url: to_Number
    [String]:
      to_str: to_String ""
      by_str: to_String undefined
      by_url: to_String undefined
    [Array]:
      to_str: (o)-> JSON.stringify(o) || []
      by_str: (o)-> JSON.parse(o) || []
      by_url: to_Array
    [Object]:
      to_str: (o)-> JSON.stringify(o) || {}
      by_str: (o)-> JSON.parse(o) || {}
}
