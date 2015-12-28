-include Makefile.config

TESTS = console lwt io_page \
        block kv_ro kv_ro_crunch \
        network stackv4 ethifv4 netif-forward ping ping6 dhcp dns \
        conduit_server conduit_server_manual \
        static_website static_website_tls http-fetch \
        # xen


ifdef WITH_TRACING
TESTS += tracing
endif

CONFIGS = $(patsubst %, %-configure, $(TESTS))
BUILDS  = $(patsubst %, %-build,     $(TESTS))
RUNS    = $(patsubst %, %-run,       $(TESTS))
CLEANS  = $(patsubst %, %-clean,     $(TESTS))

all: build

configure: $(CONFIGS)
build: $(BUILDS)
run: $(RUNS)
clean: $(CLEANS)

## lwt special cased
lwt: lwt-clean lwt-build
lwt-configure:
	@ :

lwt-build:
	$(MAKE) -C lwt build

lwt-clean:
	$(MAKE) -C lwt clean

## default tests
%-configure:
	$(MIRAGE) configure $*/config.ml --$(MODE) $(FLAGS)

%-build: %-configure
	cd $* && $(MAKE)

%-clean:
	$(MIRAGE) clean $*/config.ml
	$(RM) log

## create raw device for block_test
UNAME_S := $(shell uname -s)
block_test/disk.raw:
	[ "$(PLATFORM)" = "Darwin" ] && \
	  hdiutil create -sectors 12 -layout NONE disk.raw && \
	  mv disk.raw.dmg block_test/disk.raw
