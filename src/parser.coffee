###
# @author  Argi Karunia <https://github.com/hkyo89>
# @link    https://github.com/tokopedia/nodame
# @license http://opensource.org/licenses/MIT
#
# @version 1.0.0
###

sha512  = require('js-sha512').sha512

class Parser
  ###
  # @method Read json object by given path
  # @public
  # @param object Object
  # @param string params
  # @return object
  ###
  read: (obj, params) ->
    throw ReferenceError 'obj is undefined' unless obj?
    throw ReferenceError 'params is undefined' unless params?

    if typeof params is 'string'
      params = params.split('.')
    if params.length is 0
      return obj
    if params.length > 1
      obj = obj[params[0]]
      params.shift()
      @read obj, params
    else
      obj = obj[params[0]]
      return obj
  ###
  # @method Parse object variable
  # @private
  # @param object Object
  # @param string params
  ###
  __parse_var: (obj, str) ->
    found = str.match(/\{{2} *[a-z0-9._]+ *\}{2}/gi)

    if found?
      for i of found
        search = found[i]
        params = search.match(/[a-z0-9._]+/i)
        return str unless params?

        params = params[0]
        # Check this
        replace = @read(@__object, params)
        str = str.replace(search, replace)
    return str
  ###
  # @method Parse function
  # @private
  # @param string function name
  # @return function return
  ###
  __parse_fn: (str) ->
    found = str.match /(\(.+\|[a-z_]+\))/gi

    if found?
      for i of found
        search = found[i]
        vars = search.replace(/[()]+/g, '')
        vars = vars.split('|')

        if vars[1] is 'url_encode'
          replace = encodeURIComponent(vars[0])
          str = str.replace(search, replace)
    return str
  ###
  # @method Parse object variable
  # @public
  # @param object Object
  # @param string params
  ###
  parse_var: (obj, path = [], root = true) ->
    if typeof obj is 'object'
      # Potential to race-condition
      # TODO: Think better way to avoid reace condition
      # without passing undeclared Parser object!
      @__object = obj if root
      for i of obj
        if typeof obj[i] is 'string'
          obj[i] = @__parse_var(obj, obj[i])
          obj[i] = @__parse_fn(obj[i])
        else
          _path = path.slice()
          _path.push(i)
          @parse_var(obj[i], _path, false)
  ###
  # @method Parse to grunt
  # @public
  # @param obj json
  # @return obj json
  ###
  to_grunt: (json) ->
    grunt = {}
    for groups of json
      for group of json[groups]
        for type of json[groups][group]
          grunt[type] = [] unless grunt[type]?

          base_name = "#{groups}.#{group}"
          hash = @__hash("#{base_name}#{type}", 8)
          dest = "#{base_name}.min.#{hash}.#{type}"
          dest_src = {}
          dest_src[dest] = []
          base_dir = ''

          if json[groups]?[group]?[type]?.length > 0
            for j of json[groups][group][type]
              filename = json[groups][group][type][j]

              if filename?
                _filepath = "#{base_dir}#{json[groups][group][type][j]}"
                dest_src[dest].push(_filepath)
            grunt[type].push(dest_src)
    return grunt
  ###
  # @method Hash grunt unique name
  # @public
  # @param str
  # @param int
  # @return hashed string
  ###
  __hash: (str, len) ->
    hash = sha512("#{str}#{new Date()}")

    if len? and len < hash.length
      len_med = Math.floor(hash.length / 2)
      start = if len < len_med then len_med - Math.floor(len / 2) else 0
      hash = hash.substr(start, len)
    return hash
# Export module
module.exports = new Parser()
