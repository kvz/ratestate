util  = require "util"
fs    = require "fs"
hash  = require "object-hash"
debug = require("debug")("Ratestate:Ratestate")

class Ratestate
  constructor: (config) ->
    @_desiredStates = {}
    @_currentHashes = {}
    @_desiredHashes = {}
    @_objectIds     = []
    @_pointer       = 0
    @_config        =
      interval: 30
      hashFunc: hash
      worker  : (objectId, state, cb) ->
        console.log "Processing #{objectId}"
        cb null

    if config?
      for key, val of config
        @_config[key] = val

  setState: (objectId, desiredState) ->
    desiredHash = @_config.hashFunc desiredState
    if @_currentHashes[objectId]? && @_currentHashes[objectId] == desiredHash
      return

    if objectId not in @_objectIds
      @_objectIds.push(objectId)

    @_desiredHashes[objectId] = desiredHash
    @_desiredStates[objectId] = desiredState
    # debug util.inspect
    #   states      : @_desiredStates
    #   hashes      : @_desiredHashes
    #   objectId    : objectId
    #   desiredState: desiredState

  run: () ->
    len = @_objectIds.length - 1
    for i in [0..len] when i >= @_pointer
      objectId     = @_objectIds[i]
      desiredState = @_desiredStates[objectId]

      @_pointer++
      if @_pointer > len
        @_pointer = 0

      if @_currentHashes[objectId] != @_desiredHashes[objectId]
        @_config.worker objectId, desiredState, (err) =>
          if !err
            @_currentHashes[objectId] = @_desiredHashes[objectId]

        break

  start: () ->
    @timer = setInterval @run.bind(this), @_config.interval

  stop: () ->
    clearInterval @timer

module.exports = Ratestate
