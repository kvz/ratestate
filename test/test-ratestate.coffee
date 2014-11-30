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

      state = ratestate.getState 1

      expect(state).to.deep.equal
        color: "purple"

      done()

  describe "start", ->
    it "should start interval", (done) ->
      stopAfter   = 1000 # 1 sec
      errorMargin = .20  # Allow timing to be 20 % off
      calls       = {}
      colored     = {}
      config      =
        interval: 30
        worker  : (id, state, cb) ->
          colored[id]  = state.color
          calls[id] ?= 0
          calls[id]++
          debug "Setting lamp #{id} to #{state.color}"
          cb null

      expectedCalls = Math.floor(stopAfter / config.interval)
      maxDifference = Math.floor(expectedCalls * errorMargin)

      ratestate = new Ratestate config
      ratestate.setState 1, color: "purple"

      ratestate.setState 2, color: "green"

      setState = (id, state, delay) ->
        setTimeout ->
          debug "setState #{state.color} in #{delay}ms"
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

