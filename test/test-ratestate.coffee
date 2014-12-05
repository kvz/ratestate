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

      ratestate = new Ratestate
        hashFunc: (state) ->
          return [
            state.status
            state.bytes_received - (state.bytes_received % megabyte)
            state.uploads.length
            state.results.length
          ].join "-"

      ratestate.setState 1, status
      expect(ratestate._desiredHashes[1]).to.equal "UPLOADING-653908770816-1-2"

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

