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

ratestate.setState 1, color: "purple"
ratestate.setState 1, color: "green"
ratestate.setState 1, color: "yellow"
ratestate.setState 1, color: "yellow"
ratestate.setState 1, color: "yellow"
ratestate.setState 1, color: "green"
```

In this example, entity `1` will reach `"green"` and probably wont be set to any other intermediate state (color in this case), as we're setting the state much faster than our configured `interval`.

## Behavior and Limitations

Ratestate is similar to Underscore's [debounce](http://underscorejs.org/#debounce), but it runs indefintely and assumes you want to update the state of different entities, but for all entities you are globally speed limited. For instance you might want to

 - Continously update 20 different `.json` files on S3, but your server/network only allows a few updates per second.
 - Flush the current status of visitors to disk for caching, but throttle the total throughput as to not wear out your harddisk or cause high load.
 - Capture dominant colors from camera and push those onto Philips HUE lamps, but the combined throughput is capped by a rate-limiter on the central Bridge.

You can call `setState` as much as you'd like, and Ratestate will

 - Only transmit at a maximum speed every configured `interval`ms
 - Take care of an even spread between the entities
 - Not execute `worker` if the state has not changed
 - Consider the last pushed state for an entity leading, it will **not** attempt to transmit **every** state if more states are set than can be transmitted

By default, ratestate detects if a state has changed by comparing hashes of set state objects. If that's too heavy for your usecase (your states are huge - your frequency high), you can supply your own function that will be executed on the `state` object (it should just return a unique string for that entity's state, e.g. `return state.color` or `return state.bytes_received`).

## Todo

 - [ ] Allow to use your own hashing function (currently only full hashing is implemented)
 - [ ] Implement a gracefull `shutdown`, that at least sends the final state for each entity one time, before returning its callback

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
