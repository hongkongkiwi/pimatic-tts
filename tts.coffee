# #TTS Plugin

# This is an plugin to read text to speech from the audio speaker

# ##The plugin code
module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  #util = env.require 'util'
  os = require 'os'
  M = env.matcher

  say = require 'say'
  say.speak = Promise.promisify(say.speak);
  googleTTS = Promise.promisify(require './google-tts-api-wrapper')

  # ###Play class
  class TTSPlugin extends env.plugins.Plugin

    # ####init()
    init: (app, @framework, @config) =>

      #if os.platform() isnt 'win32'

      # player = config.player
      # env.logger.debug "play: player=#{player}"
      # playService = new Play()
      # playService.usePlayer(player) if player?

      @framework.ruleManager.addActionProvider(new TTSActionProvider @framework, @config)

  # Create a instance of my plugin
  plugin = new TTSPlugin

  class TTSActionProvider extends env.actions.ActionProvider

    constructor: (@framework, @config) ->
      return

    parseAction: (input, context) =>
      if @config.engine is "local" and (@config.voice? or @config.speed?) and (os.platform() is 'win32' or os.platform() is 'win64')
        env.logger.warn 'Please note that when using TTS on Windows, the voice or speed cannot be changed'

      defaultVoice = @config.voice or "Princess"
      defaultSpeed = @config.speed or 1
      defaultEngine = @config.engine or "local"
      defaultLanguage = @config.language or "en"

      # Helper to convert 'some text' to [ '"some text"' ]
      strToTokens = (str) => ["\"#{str}\""]

      textTokens = strToTokens ""
      speedTokens = strToTokens defaultSpeed
      voiceTokens = strToTokens defaultVoice
      engineTokens = strToTokens defaultEngine
      languageTokens = strToTokens defaultLanguage

      setText = (m, tokens) => textTokens = tokens
      setSpeed = (m, tokens) => speedTokens = tokens
      setVoice = (m, tokens) => voiceTokens = tokens
      setEngine = (m, tokens) => engineTokens = tokens
      setLanguage = (m, tokens) => languageTokens = tokens

      m = M(input, context)
        .match(['speak ','tts ','talk ','saytts '])
        .match(['text ','words ','speech '], optional: yes)
        .matchStringWithVars(setText)

      next = m.match([' with voice ',' voice:',' voice: ']).matchStringWithVars(setVoice)
      if next.hadMatch() then m = next

      next = m.match([' using speed ',' speed:',' speed: ']).matchNumericExpression(setSpeed)
      if next.hadMatch() then m = next

      next = m.match([' using language ',' language: ', ' language:']).matchStringWithVars(setLanguage)
      if next.hadMatch() then m = next

      next = m.match([' using engine ',' engine: ', ' engine:']).matchStringWithVars(setEngine)
      if next.hadMatch() then m = next

      # if m.hadMatch()
      #   m.match([' with voice '], (next) =>
      #     next.matchStringWithVars(setVoice)
      #   )
      #   m.match([' using speed '], (next) =>
      #     next.matchNumericExpression(setSpeed)
      #   )
      #   .match([' voice:', ' voice: '], optional: yes)
      #   .matchStringWithVars(setVoice)
      # if next.hadMatch() then m = next
      #
      #
      #   .match([' speed:',' speed: '], optional: yes)
      #   .matchNumericExpression(setSpeed)
        # .match(' engine:', optional: yes).matchStringWithVars(setEngine)
        # .match(' language:', optional: yes).matchStringWithVars(setLanguage)

      # next = m.match(' speed:', optional: yes).matchStringWithVars(setSpeed)
      # if next.hadMatch() then m = next
      #
      # next = m.match(' voice:', optional: yes).matchStringWithVars(setVoice)
      # if next.hadMatch() then m = next

      # next = m.match(' engine:', optional: yes).matchStringWithVars(setEngine)
      # if next.hadMatch() then m = next
      #
      # next = m.match(' language:', optional: yes).matchStringWithVars(setLanguage)
      # if next.hadMatch() then m = next

      if m.hadMatch()
        match = m.getFullMatch()

        assert Array.isArray(textTokens)
        assert Array.isArray(speedTokens)
        assert Array.isArray(voiceTokens)
        assert Array.isArray(engineTokens)
        assert Array.isArray(languageTokens)

        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new TTSActionHandler(
            @framework, textTokens, speedTokens, voiceTokens, engineTokens, languageTokens
          )
        }

  class TTSActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @textTokens, @speedTokens, @voiceTokens, @engineTokens, @languageTokens) ->

    executeAction: (simulate, context) ->
      Promise.all( [
        @framework.variableManager.evaluateStringExpression(@textTokens)
        @framework.variableManager.evaluateStringExpression(@speedTokens)
        @framework.variableManager.evaluateStringExpression(@voiceTokens)
        @framework.variableManager.evaluateStringExpression(@engineTokens)
        @framework.variableManager.evaluateStringExpression(@languageTokens)
      ]).then( ([text,speed,voice,engine,language]) =>
        return new Promise((resolve, reject) ->
          if simulate
            return resolve(__("Would Speak '#{text}' (#{voice}, #{speed})"))
          else
            if engine is "local"
              return say.speak(text, voice, speed)
                .then -> resolve __("Spoke '#{text}' (#{voice}, #{speed})")
                .catch (err) -> reject env.logger.error err
            else
              return googleTTS(text,language,speed)
              .then(function (url) {
                console.log(url); // https://translate.google.com/translate_tts?...
              })
              .catch(function (err) {
                console.error(err.stack);
              });
        )
      )

  module.exports.TTSActionHandler = TTSActionHandler

  # and return it to the framework.
  return plugin
