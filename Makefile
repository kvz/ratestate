SHELL := /bin/bash
COFFEE     = node_modules/.bin/coffee
COFFEELINT = node_modules/.bin/coffeelint
MOCHA      = node_modules/.bin/mocha --compilers coffee:coffee-script --require "coffee-script/register"
REPORTER   = spec

lint:
	@[ ! -f coffeelint.json ] && $(COFFEELINT) --makeconfig > coffeelint.json || true
	$(COFFEELINT) --file ./coffeelint.json src

build:
	make lint || true
	$(COFFEE) $(CSOPTS) --map --compile --output lib src

test: build
	DEBUG=Ratestate:* $(MOCHA) --reporter $(REPORTER) test/ --grep "$(GREP)"

compile:
	@echo "Compiling files"
	time make build

run-upload:
	source env.sh && make build && DEBUG=Ratestate:* ./bin/ratestate.js upload ./test/fixtures/test.md

run-download:
	source env.sh && make build && DEBUG=Ratestate:* ./bin/ratestate.js download -

watch:
	watch -n 2 make -s compile

release-major: build test
	npm version major -m "Release %s"
	git push
	npm publish

release-minor: build test
	npm version minor -m "Release %s"
	git push
	npm publish

release-patch: build test
	npm version patch -m "Release %s"
	git push
	npm publish

.PHONY: \
	test \
	lint \
	build \
	download-real \
	upload-real \
	sync-real \
	run-download \
	run-upload \
	release-major \
	release-minor \
	release-patch \
	compile \
	watch
