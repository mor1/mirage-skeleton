-include Makefile.config

TESTS = console network stackv4 ethifv4 io_page lwt ping static_website dns \
        conduit_server conduit_server_manual static_website_tls http-fetch \
        dhcp hello block

ifdef WITH_TRACING
TESTS += tracing
endif

CONFIGS = $(patsubst %, %-configure, $(TESTS))
BUILDS  = $(patsubst %, %-build,     $(TESTS))
RUNS    = $(patsubst %, %-run,       $(TESTS))
TESTRUN = $(patsubst %, %-testrun,   $(TESTS))
CLEANS  = $(patsubst %, %-clean,     $(TESTS))

all: build

configure: $(CONFIGS)
build: $(BUILDS)
run: $(RUNS)
testrun: $(TESTRUN)
clean: $(CLEANS)

## lwt special cased
lwt: lwt-clean lwt-build
lwt-configure:
	@ :

lwt-build:
	$(MAKE) -C lwt build

lwt-clean:
	$(MAKE) -C lwt clean

lwt-testrun:
	@ :

## block build (needs to generate disk.img)
block-build: block-configure
	cd block && $(MAKE) && ./generate_disk_img.sh

## default tests
%-configure:
	$(MIRAGE) configure -f $*/config.ml --$(MODE) $(MIRAGE_FLAGS)

%-build: %-configure
	cd $* && $(MAKE)

%-clean:
	$(MIRAGE) clean -f $*/config.ml
	$(RM) log

%-testrun:
	$(SUDO) sh ./testrun.sh $*

## create raw device for block_test
UNAME_S := $(shell uname -s)
block_test/disk.raw:
	[ "$(PLATFORM)" = "Darwin" ] && \
	  hdiutil create -sectors 12 -layout NONE disk.raw && \
	  mv disk.raw.dmg block_test/disk.raw
