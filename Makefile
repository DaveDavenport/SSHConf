.PHONY: build
build:
	./waf build

.PHONY: configure
configure:
	./waf configure

.PHONY: run
run: configure build
	./build/default/sshconf
