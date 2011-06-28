.PHONY: build
build:
	./waf build

.PHONY: configure
configure:
	./waf configure

.PHONY: run
run: configure build
	./build/default/sshconf

.PHONY: clean
clean:
	./waf clean

.PHONY: install
install:
	./waf install
