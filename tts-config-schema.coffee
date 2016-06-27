module.exports = {
  title: "TTS Plugin Config Options"
  type: "object"
  properties:
    debug:
      description: "Debug mode. Writes debug messages to the pimatic log, if set to true."
      type: "boolean"
      default: false
    voice:
      description: "Which voice to play (local engine only)"
      type: "string"
      default: "Princess"
    speed:
      description: "How fast to play the voice (local engine only)"
      type: "number"
      default: 0.75
    language:
      description: "What language to use when using the Google engine"
      type: "string"
      default: "en"
    engine:
      description: "Which engine to use for Text to Speech"
      type: "string"
      enum: ["local","google"]
      default: "local"
}
