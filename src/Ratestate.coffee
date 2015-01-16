util  = require "util"
fs    = require "fs"
hash  = require "object-hash"
debug = require("debug")("Ratestate:Ratestate")

class Ratestate
  constructor: (config) ->
    @_desiredStates        = {}
    @_currentHashes        = {}
    @_desiredHashes        = {}
    @_entityStateCallbacks = {}
    @_workerInProgress     = {}
    @_entityIds            = []
    @_pointer              = 0
    @_config               =
      interval: 30
      hashFunc: hash
      worker  : (entityId, state, cb) ->
        # debug "Processing #{entityId}"
        cb null
      drained: ->
        # debug "Drained"

    if config?
      for key, val of config
        @_config[key] = val

  finalState: (entityId, desiredState, cb) ->
    if !cb
      throw new Error "Callback required"

    @setState entityId, desiredState, (err) =>
      @removeEntity entityId

      cb err

  removeEntity: (entityId) ->
    for id, idx in @_entityIds
      if id == entityId
        # Deleting an element from an array does not lower the length.
        # Splicing does:
        @_entityIds.splice idx, 1
        break

    delete @_desiredStates[entityId]
    delete @_desiredHashes[entityId]
    delete @_currentHashes[entityId]
    delete @_entityStateCallbacks[entityId]
    delete @_workerInProgress[entityId]

  setState: (entityId, desiredState, cb) ->
    desiredStateCopy = JSON.parse JSON.stringify(desiredState)
    desiredHash = @_config.hashFunc desiredStateCopy

    if @_currentHashes[entityId]? && @_currentHashes[entityId] == desiredHash
      if cb?
        cb null
      return

    if entityId not in @_entityIds
      # Discovered a new entity, let everybody know
      @_entityIds.push entityId
      @_entityStateCallbacks[entityId] = []

    if cb?
      @_entityStateCallbacks[entityId].push cb

    @_desiredHashes[entityId] = desiredHash
    @_desiredStates[entityId] = desiredState
    # debug util.inspect
    #   states      : @_desiredStates
    #   hashes      : @_desiredHashes
    #   entityId    : entityId
    #   desiredState: desiredState

  run: ->
    checked = 0
    for i in [@_pointer..(@_entityIds.length-1)]
      entityId     = @_entityIds[i]
      desiredState = @_desiredStates[entityId]
      desiredHash  = @_desiredHashes[entityId]
      cbs          = @_entityStateCallbacks[entityId]

      checked++
      @_pointer++
      if @_pointer >= @_entityIds.length
        @_pointer = 0

      if @_currentHashes[entityId] != @_desiredHashes[entityId]
        if @_workerInProgress[entityId] == true
          # To avoid concurrently working the same entity, we'll
          # discard calling worker now.
          #
          # However we do not touch the desired state, so that will
          # either be overwritten by a later (better) state, still
          # be executed later on.
          continue

        # reset callback queue when we start a new worker
        # so that for subsequent calls there can be a new queue
        @_entityStateCallbacks[entityId] = []

        @_workerInProgress[entityId] = true
        @_config.worker entityId, desiredState, (err) =>
          @_workerInProgress[entityId] = false

          if !err
            @_currentHashes[entityId] = desiredHash

          # setState can optionally carry a last cb argument,
          # which is saved upon call, and executed here.
          # execute all callbacks that have been queued up
          if cbs?
            for cb in cbs
              cb err, desiredState

        return

      # if there were calls to setState with the same desired hash during
      # the execution of the worker, we will have a queue of callbacks, which
      # we will also need to clear/call back when the worker is finished.
      if cbs? && !@_workerInProgress[entityId]
        @_entityStateCallbacks[entityId] = []

        for cb in cbs
          cb null, desiredState

      if checked == @_entityIds.length && @_entityIds.length > 0
        if @_config.drained?
          @_config.drained()

  start: ->
    @timer = setInterval @run.bind(this), @_config.interval

  stop: ->
    clearInterval @timer

module.exports = Ratestate
