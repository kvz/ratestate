<!-- badges/ -->
[![Build Status](https://secure.travis-ci.org/kvz/ratestate.png?branch=master)](http://travis-ci.org/kvz/ratestate "Check this project's build status on TravisCI")
[![NPM version](http://badge.fury.io/js/ratestate.png)](https://npmjs.org/package/ratestate "View this project on NPM")
[![Dependency Status](https://david-dm.org/kvz/ratestate.png?theme=shields.io)](https://david-dm.org/kvz/ratestate)
[![Development Dependency Status](https://david-dm.org/kvz/ratestate/dev-status.png?theme=shields.io)](https://david-dm.org/kvz/ratestate#info=devDependencies)
<!-- /badges -->

# ratestate

A ratelimiter that can transmit states of different objects while avoiding transmitting the same state twice, and adhering to a global speed limit.

Use case: having many updates for Philips Hue intelligent lightbulbs (e.g. based on realtime color detection of camera input), memoizing the latest desired state internally, but only submitting max 30 updates / sec, to avoid hitting the global rate limiter as imposed by the Hue Bridge.

## Install

```bash
npm install --save ratestate
```

## Use

Here's a little coffeescript example

```coffeescript
ratestate = new Ratestate
  interval: 30
  worker  : (id, state, cb) ->
    # Transmit the state to id
    cb null

ratestate.start()
ratestate.setState 1, color: "purple"
ratestate.setState 1, color: "green"
ratestate.setState 1, color: "yellow"
ratestate.setState 1, color: "yellow"
ratestate.setState 1, color: "yellow"
ratestate.setState 1, color: "green"
ratestate.stop()
```

In this example, entity `1` will reach `"green"` and probably wont be set to any other intermediate state (color in this case), as we're setting the state much faster than our configured `interval`.

## Behavior and Limitations

Ratestate is similar to Underscore's [debounce](http://underscorejs.org/#debounce), but it runs indefintely and assumes you want to update the state of different entities, but for all entities you are globally speed limited. For instance you might want to

 - Continously update 20 different `.json` files on S3, but your server/network only allows a few updates per second.
 - Flush the current status of visitors to disk for caching, but throttle the total throughput as to not wear out your harddisk or cause high load.
 - Capture dominant colors from a video feed at 60 frames per second, and push those colors to Philips HUE lamps, but the combined throughput to them is capped by a rate-limiter on the central Bridge, allowing you to at most only pass through 30 colors per second total.

You can call `setState` as much as you'd like, and Ratestate will

 - Only transmit at a maximum speed every configured `interval`ms
 - Take care of an even spread between the entities
 - Not execute `worker` if the state has not changed
 - Consider the last pushed state for an entity leading, it will **not** attempt to transmit **every** state if more states are set than can be transmitted

## Custom hashing

By default, ratestate detects if a state has changed by comparing hashes of set state objects it won't consider executing the `worker` on states that have not changed.

If the built-in serializing & hashing is too heavy for your usecase (your states are huge - your frequency high), you can supply your own function that will be executed on the `state` object to determine its uniqueness. In the following example we'll supply our own `hashFunc` to determine if the state is a candidate for passing to the `worker`.

```coffeescript
megabyte = 1024 * 1024 * 1024
status   =
  id            : "abcdefghijklmnopqrstuvw"
  status        : "UPLOADING"
  bytes_received: 2073741824
  client_agent  : "Mozilla/5.0 (Windows NT 6.0; rv:34.0) Gecko/20100101 Firefox/34.0"
  client_ip     : "189.3.31.70"
  uploads       : [
    name: "tesla.jpg"
  ]
  results: [
    original:
      name: "tesla.jpg"
  ,
    resized:
      name: "tesla-100px.jpg"
  ]

ratestate = new Ratestate
  hashFunc: (state) ->
    return [
      state.status
      state.bytes_received - (state.bytes_received % megabyte)
      state.uploads.length
      state.results.length
    ].join "-"

ratestate.start()
ratestate.setState "abcdefghijklmnopqrstuvw", status
# And many more setStates throughout the lifetime of you program
ratestate.stop()
```

This would internally be hashed to as `UPLOADING-653908770816-1-2`, if we detect a change in our system and blindly call `setState`, this won't execute `worker` if

 - The `status` has not changed, AND
 - We have less than a new megate of `bytes_received`, AND
 - The amount of `uploads` is still the same, AND
 - The amount of `results` is still the same

Cool and a lot more efficient than serializing and hashing an entire object.

## Todo

 - [ ] Implement a lock per entity to avoid concurrent writes. But: how can we then guarantee the last write wins? Delaying it? That might get messy.
 - [ ] Remove `@_desiredStates` bookkeeping for effieciency. Test cases can compare against `@_desiredHashes` using `object-hash`
 - [ ] Implement a gracefull `shutdown`, that at least sends the final state for each entity one time, before returning its callback
 - [ ] Implement a forcefull `start`, so that intervals are ignored if we don't have a previous state on the entity yet.
 - [x] Allow to use your own hashing function (currently only full hashing is implemented)

### Compile

This project is written in [CoffeeScript](http://coffeescript.org/), and the JavaScript it generates is written to `./lib`. This is only used so that people can use this node module without a CoffeeScript dependency. If you want to work on the source, please do so in `./src` and type: `make build` or `make test` (also builds first). Please don't edit generated JavaScript in `./lib`!


## Contribute

I'd be happy to accept pull requests. If you plan on working on something big, please first give a shout!


### Test

Run tests via `make test`.

To single out a test use `make test GREP=30x`


### Release

Releasing a new version to npmjs.org can be done via `make release-patch` (or minor / major, depending on the [semantic versioning](http://semver.org/) impact of your changes). This:

 - Updates the `package.json`
 - Saves a release commit with the updated version in Git
 - Pushes to GitHub
 - Publishes to npmjs.org

## Authors

 - [Kevin van Zonneveld](https://twitter.com/kvz)

## License

[MIT Licensed](LICENSE).

## Sponsor Development

Like this project? Consider a donation.
You'd be surprised how rewarding it is for me see someone spend actual money on these efforts, even if just $1.

<!-- badges/ -->
[![Gittip donate button](http://img.shields.io/gittip/kvz.png)](https://www.gittip.com/kvz/ "Sponsor the development of ratestate via Gittip")
[![Flattr donate button](http://img.shields.io/flattr/donate.png?color=yellow)](https://flattr.com/submit/auto?user_id=kvz&url=https://github.com/kvz/ratestate&title=ratestate&language=&tags=github&category=software "Sponsor the development of ratestate via Flattr")
[![PayPal donate button](http://img.shields.io/paypal/donate.png?color=yellow)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=kevin%40vanzonneveld%2enet&lc=NL&item_name=Open%20source%20donation%20to%20Kevin%20van%20Zonneveld&currency_code=USD&bn=PP-DonationsBF%3abtn_donate_SM%2egif%3aNonHosted "Sponsor the development of ratestate via Paypal")
[![BitCoin donate button](http://img.shields.io/bitcoin/donate.png?color=yellow)](https://coinbase.com/checkouts/19BtCjLCboRgTAXiaEvnvkdoRyjd843Dg2 "Sponsor the development of ratestate via BitCoin")
<!-- /badges -->
