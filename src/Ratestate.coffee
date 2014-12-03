util  = require "util"
fs    = require "fs"
hash  = require "object-hash"
debug = require("debug")("Ratestate:Ratestate")

class Ratestate
  constructor: (config) ->
    @_desiredStates = {}
    @_currentHashes = {}
    @_desiredHashes = {}
    @_entityIds     = []
    @_pointer       = 0
    @_config        =
      interval: 30
      hashFunc: hash
      worker  : (entityId, state, cb) ->
        console.log "Processing #{entityId}"
        cb null

    if config?
      for key, val of config
        @_config[key] = val

  setState: (entityId, desiredState) ->
    desiredHash = @_config.hashFunc desiredState
    if @_currentHashes[entityId]? && @_currentHashes[entityId] == desiredHash
      return

    if entityId not in @_entityIds
      @_entityIds.push(entityId)

    @_desiredHashes[entityId] = desiredHash
    @_desiredStates[entityId] = desiredState
    # debug util.inspect
    #   states      : @_desiredStates
    #   hashes      : @_desiredHashes
    #   entityId    : entityId
    #   desiredState: desiredState

  run: ->
    len = @_entityIds.length - 1
    for i in [0..len] when i >= @_pointer
      entityId     = @_entityIds[i]
      desiredState = @_desiredStates[entityId]

      @_pointer++
      if @_pointer > len
        @_pointer = 0

      if @_currentHashes[entityId] != @_desiredHashes[entityId]
        @_config.worker entityId, desiredState, (err) =>
          if !err
            @_currentHashes[entityId] = @_desiredHashes[entityId]

        break

  start: ->
    @timer = setInterval @run.bind(this), @_config.interval

  stop: ->
    clearInterval @timer

module.exports = Ratestate
