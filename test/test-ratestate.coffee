should      = require("chai").should()
debug       = require("debug")("Ratestate:test-ratestate")
util        = require "util"
fs          = require "fs"
expect      = require("chai").expect
fixture_dir = "#{__dirname}/fixtures"
Ratestate   = require "../src/Ratestate"

describe "Ratestate", ->
  @timeout 10000 # <-- This is the Mocha timeout, allowing tests to run longer

  describe "setState", ->
    it "should set last item", (done) ->
      ratestate = new Ratestate

      ratestate.setState 1, color: "red"
      ratestate.setState 1, color: "green"
      ratestate.setState 1, color: "purple"
      state = ratestate._desiredStates[1]
      expect(state).to.deep.equal
        color: "purple"

      done()

    it "should allow custom hashing", (done) ->
      megabyte = 1024 * 1024 * 1024
      status   =
        id            : 1
        status        : "UPLOADING"
        bytes_received: 654935654935
        client_agent  : "Mozilla/5.0 (Windows NT 6.0; rv:34.0) Gecko/20100101 Firefox/34.0"
        client_ip     : "189.3.31.70"
        uploads       : [
          name: "tesla.jpg"
        ]
        results       : [
          ":original":
            name: "tesla.jpg"
        ,
          resized:
            name: "tesla-100px.jpg"
        ]

      ratestate = new Ratestate
      ratestate.setState 1, status
      expect(ratestate._desiredHashes[1]).to.deep.equal "d8ef52d2fbdb618db0919f8046cb237ee40bb3aa"

      workerHasIpTestCalls = 0
      ratestate = new Ratestate
        worker: (entityId, state, cb) ->
          expect(state.client_ip).to.equal "189.3.31.70"
          workerHasIpTestCalls++
          cb()

        hashFunc: (state) ->
          delete state.client_ip

          return [
            state.status
            state.bytes_received - (state.bytes_received % megabyte)
            state.uploads.length
            state.results.length
          ].join "-"

      ratestate.start()
      ratestate.setState 1, status, ->
        expect(ratestate._desiredHashes[1]).to.equal "UPLOADING-653908770816-1-2"
        expect(workerHasIpTestCalls).to.equal 1

        ratestate.stop()
        done()

  describe "finalState", ->
    it "should clean up entity", (done) ->
      ratestate = new Ratestate

      ratestate.start()
      ratestate.setState 1, color: "red"
      ratestate.setState 1, color: "green"
      ratestate.finalState 1, color: "purple", (err) ->
        # debug ratestate._entityIds
        expect(ratestate._entityIds.length).to.equal 0
        ratestate.stop()
        done()


  describe "start", ->
    it "should not allow multiple concurrent workers on a single entity", (done) ->
      calls         = {}
      colors        = {}
      workerRunning =
        1: false
        2: false

      ratestate = new Ratestate
        # A fast interval
        interval: 1
        # A slow worker
        worker: (id, state, cb) ->
          expect(workerRunning[id]).to.equal false
          workerRunning[id] = true

          calls[id] ?= 0
          calls[id]++
          colors[id] = state.color

          setTimeout ->
            workerRunning[id] = false
            cb null
          , 250
        drained: ->
          # debug "Drained"
          ratestate.stop()
          expect(calls[1]).to.equal 2
          expect(calls[2]).to.equal 2
          expect(colors[1]).to.equal "yellow"
          expect(colors[2]).to.equal "yellow"
          done()

      ratestate.start()

      setTimeout ->
        ratestate.setState 1, color: "purple"
        ratestate.setState 2, color: "purple"
      , 100
      setTimeout ->
        ratestate.setState 1, color: "green"
        ratestate.setState 2, color: "green"
      , 200
      setTimeout ->
        ratestate.setState 1, color: "yellow"
        ratestate.setState 2, color: "yellow"
      , 300


    it "should execute multiple calls, and make sure last write wins", (done) ->
      stopAfter   = 1000 # 1 sec
      errorMargin = .20  # Allow timing to be 20 % off
      calls       = {}
      colored     = {}
      config      =
        interval: 30
        worker  : (id, state, cb) ->
          colored[id] = state.color
          calls[id]  ?= 0
          calls[id]++
          # debug "Setting lamp #{id} to #{state.color}"
          cb null

      expectedCalls = Math.floor(stopAfter / config.interval)
      maxDifference = Math.floor(expectedCalls * errorMargin)

      ratestate = new Ratestate config
      ratestate.setState 1, color: "purple"
      ratestate.setState 2, color: "green"

      setState = (id, state, delay) ->
        setTimeout ->
          # debug "setState #{state.color} in #{delay}ms"
          ratestate.setState 2, state
        , delay

      for color, indx in [ "orange", "pink", "blue", "navy", "navy", "maroon", "yellow" ]
        setState 2, color: color, Math.floor(stopAfter * .20) + (10 * (indx + 1))

      ratestate.start()

      setTimeout ->
        ratestate.stop()
        expect(calls[1]).to.equal 1
        expect(colored[1]).to.equal "purple"

        expect(calls[2]).to.be.within 3, 5
        expect(colored[2]).to.equal "yellow"
        done()
      , stopAfter

    it "should execute provided callbacks of all setState calls in the right order, even if some writes are skipped", (done) ->
      stopAfter          = 8000 # 1 sec
      cbCalls            = []
      cbCallOrder        = []
      cbCallOrderTimeout = []
      colored            = {}
      interval           = 30
      config    =
        interval: interval
        worker  : (id, state, cb) ->
          setTimeout ->
            colored[id] = state.color
            cb null
          , interval * 20

      ratestate = new Ratestate config

      ratestate.setState 0, color: "purple_0", ->
        cbCalls[0] ?= 0
        cbCalls[0]++

        cbCallOrderTimeout.push "purple_0"

      # even if we have a running worker (worker takes 600ms to execute, we call
      # this after 90ms) should the callback be enqueued and executed
      setTimeout ->
        ratestate.setState 0, color: "purple_0", ->
          cbCalls[0] ?= 0
          cbCalls[0]++

          cbCallOrderTimeout.push "purple_0_2"
      , interval * 3

      ratestate.setState 1, color: "purple_1", ->
        cbCalls[1] ?= 0
        cbCalls[1]++

        cbCallOrder.push "purple_1"

      ratestate.setState 2, color: "green", ->
        cbCalls[2] ?= 0
        cbCalls[2]++

      ratestate.setState 3, color: "yellow", ->
        cbCalls[3] ?= 0
        cbCalls[3]++

      ratestate.setState 1, color: "purple_2", ->
        cbCalls[1] ?= 0
        cbCalls[1]++

        cbCallOrder.push "purple_2"

      ratestate.setState 1, color: "purple_3", ->
        cbCalls[1] ?= 0
        cbCalls[1]++

        cbCallOrder.push "purple_3"

      ratestate.setState 1, color: "purple_3", ->
        cbCalls[1] ?= 0
        cbCalls[1]++

        cbCallOrder.push "purple_3"

      ratestate.start()

      setTimeout ->
        # a setState call when the previous batch has been executed
        # should also have its callback called
        ratestate.setState 1, color: "purple_4", ->
          cbCalls[1] ?= 0
          cbCalls[1]++

          cbCallOrder.push "purple_4"

        # even saving the same state again should call the callback
        ratestate.setState 1, color: "purple_4", ->
          cbCalls[1] ?= 0
          cbCalls[1]++

          cbCallOrder.push "purple_4"

          ratestate.stop()

          expect(colored[0]).to.equal "purple_0"
          expect(colored[1]).to.equal "purple_4"
          expect(colored[2]).to.equal "green"
          expect(colored[3]).to.equal "yellow"

          expect(cbCalls[0]).to.equal 2
          expect(cbCalls[1]).to.equal 6
          expect(cbCalls[2]).to.equal 1
          expect(cbCalls[3]).to.equal 1

          expectedOrder = [
            "purple_1"
            "purple_2"
            "purple_3"
            "purple_3"
            "purple_4"
            "purple_4"
          ]
          expect(cbCallOrder).to.eql expectedOrder

          expectedOrder = [
            "purple_0"
            "purple_0_2"
          ]
          expect(cbCallOrderTimeout).to.eql expectedOrder

          done()
      , stopAfter

    it "should provide the state that was last written to all executed callbacks", (done) ->
      stopAfter     = 1000 # 1 sec
      statesWritten = []
      colored       = {}
      interval      = 30
      config        =
        interval: interval
        worker  : (id, state, cb) ->
          colored[id] = state.color
          cb null

      ratestate = new Ratestate config

      ratestate.setState 1, color: "purple_0", (err, stateWritten) ->
        statesWritten.push stateWritten

      ratestate.setState 1, color: "purple_1", (err, stateWritten) ->
        statesWritten.push stateWritten

      setTimeout ->
        ratestate.setState 1, color: "purple_2", (err, stateWritten) ->
          statesWritten.push stateWritten
      , interval * 3

      ratestate.start()

      setTimeout ->
        ratestate.stop()

        expect(colored[1]).to.equal "purple_2"

        expectedStates = [
          {color: "purple_1"}
          {color: "purple_1"}
          {color: "purple_2"}
        ]
        expect(statesWritten).to.eql expectedStates

        done()
      , stopAfter
