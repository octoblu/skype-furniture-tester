async       = require 'async'
_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'

class Tester
  constructor: ({@uuid, @meshbluConfig}) ->
    throw new Error 'Missing required parameter: uuid' unless @uuid?
    throw new Error 'Missing required parameter: meshbluConfig' unless @meshbluConfig?

    @meshblu = new MeshbluHttp @meshbluConfig

  run: (callback) =>
    async.series [
      @_startSkype
      @_waitForSkypeToStart
      @_endSkype
      @_waitForSkypeToEnd
    ], callback

  _startSkype: (callback) =>
    @meshblu.update @uuid, {
      desiredState:
        meeting:
          url: null
        audioEnabled: true
        videoEnabled: true
    }, callback

  _waitForSkypeToStart: (callback) =>
    async.until @__skypeHasStarted, @__checkIfSkypeHasStarted, callback

  _endSkype: (callback) =>
    @meshblu.update @uuid, {
      desiredState:
        meeting: null
    }, callback

  _waitForSkypeToEnd: (callback) =>
    async.until @__skypeHasEnded, @__checkIfSkypeHasEnded, callback

  __skypeHasStarted: => @___skypeHasStarted
  __checkIfSkypeHasStarted: (callback) =>
    @meshblu.device @uuid, (error, device) =>
      return callback error if error
      @___skypeHasStarted = _.get(device, 'state.videoEnabled', false)
      return _.delay callback, 500

  __skypeHasEnded: => @__skypeHasEnded
  __checkIfSkypeHasEnded: (callback) =>
    @meshblu.device @uuid, (error, device) =>
      return callback error if error
      @___skypeHasEnded = _.isNull(_.get(device, 'state.meeting'))
      return _.delay callback, 500


module.exports = Tester
