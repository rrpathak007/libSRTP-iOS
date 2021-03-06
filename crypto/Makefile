# Makefile for crypto test suite
#
# David A. McGrew
# Cisco Systems, Inc.

srcdir = .
top_srcdir = ..
top_builddir = ..


CC	= /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc
INCDIR	= -Iinclude -I$(srcdir)/include -I$(top_srcdir)/include
DEFS	= -DHAVE_CONFIG_H
CPPFLAGS= 
CFLAGS	= -arch x86_64 -mios-simulator-version-min=8.0 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator8.4.sdk  -I../openssl//include 
LIBS	= -lcrypto -lcrypto -lcrypto -lz -ldl 
LDFLAGS	= -arch x86_64 -mios-simulator-version-min=8.0 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator8.4.sdk -L../openssl//lib  -L. -L..
COMPILE = $(CC) $(DEFS) $(INCDIR) $(CPPFLAGS) $(CFLAGS)
CRYPTOLIB = -lsrtp2

RANLIB	= ranlib

# EXE defines the suffix on executables - it's .exe for cygwin, and
# null on linux, bsd, and OS X and other OSes.  we define this so that
# `make clean` will work on the cygwin platform
EXE = 
# Random source.
USE_OPENSSL = 1

ifdef ARCH
  DEFS += -D$(ARCH)=1
endif

ifdef sysname
  DEFS += -D$(sysname)=1
endif

.PHONY: dummy all runtest clean superclean

dummy : all runtest 

# test applications 
ifneq (1, $(USE_OPENSSL))
AES_CALC = test/aes_calc$(EXE)
endif

testapp = test/cipher_driver$(EXE) test/datatypes_driver$(EXE) \
	  test/stat_driver$(EXE) test/sha1_driver$(EXE) \
	  test/kernel_driver$(EXE) $(AES_CALC) \
	  test/env$(EXE)

# data values used to test the aes_calc application for AES-128
k128=000102030405060708090a0b0c0d0e0f
p128=00112233445566778899aabbccddeeff
c128=69c4e0d86a7b0430d8cdb78070b4c55a


# data values used to test the aes_calc application for AES-256
k256=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
p256=00112233445566778899aabbccddeeff
c256=8ea2b7ca516745bfeafc49904b496089


runtest: $(testapp)
	test/env$(EXE) # print out information on the build environment
	@echo "running crypto test applications..."
ifneq (1, $(USE_OPENSSL))
	test `test/aes_calc $(k128) $(p128)` = $(c128)
	test `test/aes_calc $(k256) $(p256)` = $(c256)
endif
	test/cipher_driver$(EXE) -v >/dev/null
	test/datatypes_driver$(EXE) -v >/dev/null
	test/stat_driver$(EXE) >/dev/null
	test/sha1_driver$(EXE) -v >/dev/null
	test/kernel_driver$(EXE) -v >/dev/null
	@echo "crypto test applications passed."


# the rule for making object files and test apps

%.o: %.c
	$(COMPILE) -c $< -o $@

%$(EXE): %.c ../test/getopt_s.c
	$(COMPILE) $(LDFLAGS) $< ../test/getopt_s.c -o $@ $(CRYPTOLIB) $(LIBS)

all: $(testapp)

# housekeeping functions

clean:
	rm -f $(testapp) *.o */*.o 
	for a in * .* */*; do if [ -f "$$a~" ] ; then rm $$a~; fi; done;
	rm -f `find . -name "*.[ch]~*~"`
	rm -rf latex

superclean: clean
	rm -f *core TAGS ktrace.out

# EOF
