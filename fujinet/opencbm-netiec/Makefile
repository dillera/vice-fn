# opencbm-netiec: build libopencbm (the OpenCBM ABI over NetIEC) and netiecctl.

CC      ?= cc
CFLAGS  ?= -O2 -g
CFLAGS  += -std=c99 -D_POSIX_C_SOURCE=200809L -D_DARWIN_C_SOURCE -Wall -Wextra

ifeq ($(shell uname -s),Darwin)
LIB         := libopencbm.dylib
LIB_LDFLAGS := -dynamiclib -install_name @rpath/$(LIB)
RPATH       := -Wl,-rpath,@loader_path
else
LIB         := libopencbm.so
LIB_LDFLAGS := -shared -Wl,-soname,$(LIB)
CFLAGS      += -fPIC
RPATH       := -Wl,-rpath,'$$ORIGIN'
endif

all: $(LIB) netiecctl

$(LIB): opencbm_netiec.c netiec.h
	$(CC) $(CFLAGS) -fvisibility=hidden $(LIB_LDFLAGS) -o $@ opencbm_netiec.c

netiecctl: netiecctl.c $(LIB)
	$(CC) $(CFLAGS) -o $@ netiecctl.c -L. -lopencbm $(RPATH)

clean:
	rm -rf $(LIB) netiecctl *.dSYM

.PHONY: all clean
