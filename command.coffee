async         = require 'async'
colors        = require 'colors'
dashdash      = require 'dashdash'
MeshbluConfig = require 'meshblu-config'

packageJSON = require './package.json'
Tester      = require './src/tester'

OPTIONS = [{
  names: ['uuid', 'u']
  type: 'string'
  env: 'SFT_UUID'
  help: 'UUID of the skype connector to test'
}, {
  names: ['meeting-url', 'm']
  type: 'string'
  env: 'SFT_MEETING_URL'
  help: 'Meeting url to join to'
}, {
  names: ['help', 'h']
  type: 'bool'
  help: 'Print this help and exit.'
}, {
  names: ['version', 'v']
  type: 'bool'
  help: 'Print the version and exit.'
}]

class Command
  constructor: ->
    process.on 'uncaughtException', @die
    {@meetingUrl, @uuid, @meshbluConfig} = @parseOptions()
    @count = 0

  parseOptions: =>
    parser = dashdash.createParser({options: OPTIONS})
    options = parser.parse(process.argv)
    {uuid, version, help} = options
    meetingUrl = options.meeting_url

    meshbluConfig = new MeshbluConfig().toJSON()

    if help
      console.log @usage parser.help({includeEnv: true})
      process.exit 0

    if version
      console.log packageJSON.version
      process.exit 0

    if !uuid || !meshbluConfig.resolveSrv
      console.error @usage parser.help({includeEnv: true})
      console.error colors.red 'Missing required parameter --uuid, -u, or env: SFT_UUID' unless uuid
      console.error colors.red 'Must use resolveSrv in meshblu.json' unless meshbluConfig.resolveSrv
      process.exit 1

    if !meetingUrl
      console.warn colors.yellow 'Missing --meeting-url, going to use Meet Now'

    return {uuid, meshbluConfig, meetingUrl}

  run: =>
    async.forever @singleRun, @die

  singleRun: (callback) =>
    @count += 1
    console.log 'attempt: ', @count
    tester = new Tester {@meshbluConfig, @uuid, @meetingUrl}
    tester.run callback

  die: (error) =>
    return process.exit(0) unless error?
    console.error 'ERROR'
    console.error error.stack
    process.exit 1

  usage: (optionsStr) =>
    """
    usage: skype-furniture-tester [OPTIONS]
    options:
    #{optionsStr}
    """

module.exports = Command
