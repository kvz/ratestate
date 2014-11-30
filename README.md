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


```coffeescript
```

## Todo

 - [ ] Init


### Compile

This project is written in [CoffeeScript](http://coffeescript.org/), and the JavaScript it generates is written to `./lib`. This is only used so that people can use this node module without a CoffeeScript dependency. If you want to work on the source, please do so in `./src` and type: `make build` or `make test` (also builds first). Please don't edit generated JavaScript in `./lib`!


## Contribute

I'd be happy to accept pull requests. If you plan on working on something big, please first give a shout!


### Test

Run tests via `make test`.

To single out a test use `make test GREP=30x`


### Release

Releasing a new version to npmjs.org can be done via `make release-patch` (or minor / major, depending on the [semantic versioning](http://semver.org/) impact of your changes). This:

 - updates the `package.json`
 - saves a release commit with the updated version in Git
 - pushes to GitHub
 - publishes to npmjs.org

## Authors

* [Kevin van Zonneveld](https://twitter.com/kvz)

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
