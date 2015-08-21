SHELL     := /bin/bash
COFFEE     = node_modules/.bin/coffee
COFFEELINT = node_modules/.bin/coffeelint
MOCHA      = node_modules/.bin/mocha --compilers coffee:coffee-script --require "coffee-script/register"
REPORTER   = spec

.PHONY: lint
lint:
	@[ ! -f coffeelint.json ] && $(COFFEELINT) --makeconfig > coffeelint.json || true
	$(COFFEELINT) --file ./coffeelint.json src

.PHONY: build
build:
	make lint || true
	$(COFFEE) $(CSOPTS) --map --compile --output lib src

.PHONY: test
test: build
	DEBUG=Ratestate:* $(MOCHA) --reporter $(REPORTER) test/ --grep "$(GREP)"

.PHONY: compile
compile:
	@echo "Compiling files"
	time make build

.PHONY: run-upload
run-upload:
	source env.sh && make build && DEBUG=Ratestate:* ./bin/ratestate.js upload ./test/fixtures/test.md

.PHONY: run-download
run-download:
	source env.sh && make build && DEBUG=Ratestate:* ./bin/ratestate.js download -

.PHONY: watch
watch:
	watch -n 2 make -s compile

.PHONY: release-major
release-major: build test
	npm version major -m "Release %s"
	git push
	npm publish

.PHONY: release-minor
release-minor: build test
	npm version minor -m "Release %s"
	git push
	npm publish

.PHONY: release-patch
release-patch: build test
	npm version patch -m "Release %s"
	git push
	npm publish
