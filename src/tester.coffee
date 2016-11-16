async       = require 'async'
_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'
debug       = require('debug')('sft:tester')
debugSilly  = require('debug')('sft:tester:silly')

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
    debug '_startSkype'
    @meshblu.update @uuid, {
      desiredState:
        meeting:
          url: null
        audioEnabled: true
        videoEnabled: true
    }, callback

  _waitForSkypeToStart: (callback) =>
    debug '_waitForSkypeToStart'
    async.until @__skypeHasStarted, @__checkIfSkypeHasStarted, callback

  _endSkype: (callback) =>
    debug '_endSkype'
    @meshblu.update @uuid, {
      desiredState:
        meeting: null
    }, callback

  _waitForSkypeToEnd: (callback) =>
    debug '_waitForSkypeToEnd'
    async.until @__skypeHasEnded, @__checkIfSkypeHasEnded, callback

  __skypeHasStarted: => @___skypeHasStarted
  __checkIfSkypeHasStarted: (callback) =>
    @___checkIfSkypeHasStartedCount ?= 0
    @___checkIfSkypeHasStartedCount += 1
    return callback new Error("Skype hasn't started in 20 checks") if 20 < @___checkIfSkypeHasStartedCount

    @meshblu.device @uuid, (error, device) =>
      return callback error if error
      debugSilly JSON.stringify device.state
      @___skypeHasStarted = _.get(device, 'state.videoEnabled', false)
      return _.delay callback, 500

  __skypeHasEnded: => @___skypeHasEnded
  __checkIfSkypeHasEnded: (callback) =>
    @___checkIfSkypeHasEndedCount ?= 0
    @___checkIfSkypeHasEndedCount += 1
    return callback new Error("Skype hasn't ended in 20 checks") if 20 < @___checkIfSkypeHasEndedCount

    @meshblu.device @uuid, (error, device) =>
      return callback error if error
      debugSilly JSON.stringify device.state
      @___skypeHasEnded = _.isNull(_.get(device, 'state.meeting'))
      return _.delay callback, 500

module.exports = Tester
