# Makefile for secure rtp 
#
# David A. McGrew
# Cisco Systems, Inc.

# targets:
#
# runtest       runs test applications 
# test		builds test applications
# libsrtp2.a	static library implementing srtp
# libsrtp2.so	shared library implementing srtp
# clean		removes objects, libs, and executables
# distribution  cleans and builds a .tgz
# tags          builds etags file from all .c and .h files

USE_OPENSSL = 1
HAVE_PCAP = 
HAVE_PKG_CONFIG = 0

.PHONY: all shared_library test

all: test 

runtest: test
	@echo "running libsrtp2 test applications..."
	crypto/test/cipher_driver$(EXE) -v >/dev/null
	crypto/test/kernel_driver$(EXE) -v >/dev/null
	test/rdbx_driver$(EXE) -v >/dev/null
	test/srtp_driver$(EXE) -v >/dev/null
	test/roc_driver$(EXE) -v >/dev/null
	test/replay_driver$(EXE) -v >/dev/null
	test/dtls_srtp_driver$(EXE) >/dev/null
	cd test; $(abspath $(srcdir))/test/rtpw_test.sh >/dev/null	
ifeq (1, $(USE_OPENSSL))
	cd test; $(abspath $(srcdir))/test/rtpw_test_gcm.sh >/dev/null	
endif
	@echo "libsrtp2 test applications passed."
	$(MAKE) -C crypto runtest

# makefile variables

CC	= /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc
INCDIR	= -Icrypto/include -I$(srcdir)/include -I$(srcdir)/crypto/include
DEFS	= -DHAVE_CONFIG_H
CPPFLAGS= -fPIC 
CFLAGS	= -arch x86_64 -mios-simulator-version-min=8.0 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator8.4.sdk  -I../openssl//include 
LIBS	= -lcrypto -lcrypto -lcrypto -lz -ldl 
LDFLAGS	= -L. -arch x86_64 -mios-simulator-version-min=8.0 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator8.4.sdk -L../openssl//lib 
COMPILE = $(CC) $(DEFS) $(INCDIR) $(CPPFLAGS) $(CFLAGS)
SRTPLIB	= -lsrtp2

AR      = ar
RANLIB	= ranlib
INSTALL	= /usr/bin/install -c

# EXE defines the suffix on executables - it's .exe for Windows, and
# null on linux, bsd, and OS X and other OSes.
EXE	= 

HMAC_OBJS = crypto/hash/hmac_ossl.o
AES_ICM_OBJS = crypto/cipher/aes_icm_ossl.o crypto/cipher/aes_gcm_ossl.o

srcdir = .
top_srcdir = .
top_builddir = .

prefix = /Users/aagman/Desktop/LibSRTP/SIM_x86_64
exec_prefix = ${prefix}
includedir = ${prefix}/include
libdir = ${exec_prefix}/lib
bindir = ${exec_prefix}/bin

ifeq (1, $(HAVE_PKG_CONFIG))
pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = libsrtp2.pc
endif

SHAREDLIBVERSION = 1
ifeq (linux,$(findstring linux,x86_64-apple-darwin))
SHAREDLIB_DIR = $(libdir)
SHAREDLIB_LDFLAGS = -shared -Wl,-soname,$@
SHAREDLIBSUFFIXNOVER = so
SHAREDLIBSUFFIX = $(SHAREDLIBSUFFIXNOVER).$(SHAREDLIBVERSION)
else ifeq (mingw,$(findstring mingw,x86_64-apple-darwin))
SHAREDLIB_DIR = $(bindir)
SHAREDLIB_LDFLAGS = -shared -Wl,--out-implib,libsrtp2.dll.a
SHAREDLIBVERSION =
SHAREDLIBSUFFIXNOVER = dll
SHAREDLIBSUFFIX = $(SHAREDLIBSUFFIXNOVER)
else ifeq (darwin,$(findstring darwin,x86_64-apple-darwin))
SHAREDLIB_DIR = $(libdir)
SHAREDLIB_LDFLAGS = -dynamiclib -twolevel_namespace -undefined dynamic_lookup \
        -fno-common -headerpad_max_install_names -install_name $(libdir)/$@
SHAREDLIBSUFFIXNOVER = dylib
SHAREDLIBSUFFIX = $(SHAREDLIBVERSION).$(SHAREDLIBSUFFIXNOVER)
endif

# implicit rules for object files and test apps

%.o: %.c
	$(COMPILE) -c $< -o $@

%$(EXE): %.c
	$(COMPILE) $(LDFLAGS) $< -o $@ $(SRTPLIB) $(LIBS)

ciphers = crypto/cipher/cipher.o crypto/cipher/null_cipher.o      \
          $(AES_ICM_OBJS)     

hashes  = crypto/hash/null_auth.o  crypto/hash/auth.o            \
	  $(HMAC_OBJS)

replay  = crypto/replay/rdb.o crypto/replay/rdbx.o               \
          crypto/replay/ut_sim.o 

math    = crypto/math/datatypes.o crypto/math/stat.o 

ust     = crypto/ust/ust.o 

err     = crypto/kernel/err.o

kernel  = crypto/kernel/crypto_kernel.o  crypto/kernel/alloc.o   \
          crypto/kernel/key.o $(err) # $(ust) 

cryptobj =  $(ciphers) $(hashes) $(math) $(kernel) $(replay)

# libsrtp2.a (implements srtp processing)

srtpobj = srtp/srtp.o srtp/ekt.o

libsrtp2.a: $(srtpobj) $(cryptobj) $(gdoi)
	$(AR) cr libsrtp2.a $^
	$(RANLIB) libsrtp2.a

libsrtp2.$(SHAREDLIBSUFFIX): $(srtpobj) $(cryptobj) $(gdoi)
	$(CC) -shared -o $@ $(SHAREDLIB_LDFLAGS) \
                $^ $(LDFLAGS) $(LIBS)
	if [ -n "$(SHAREDLIBVERSION)" ]; then \
		ln -sfn $@ libsrtp2.$(SHAREDLIBSUFFIXNOVER); \
	fi

shared_library: libsrtp2.$(SHAREDLIBSUFFIX)

libsrtp2.so: $(srtpobj) $(cryptobj) 
	$(CC) -shared -Wl,-soname,libsrtp2.so \
	    -o libsrtp2.so $^ $(LDFLAGS)

# test applications 
ifneq (1, $(USE_OPENSSL))
AES_CALC = crypto/test/aes_calc$(EXE)
endif

crypto_testapp = $(AES_CALC) crypto/test/cipher_driver$(EXE) \
	crypto/test/datatypes_driver$(EXE) crypto/test/kernel_driver$(EXE) \
	crypto/test/sha1_driver$(EXE) \
	crypto/test/stat_driver$(EXE) 

testapp = $(crypto_testapp) test/srtp_driver$(EXE) test/replay_driver$(EXE) \
	  test/roc_driver$(EXE) test/rdbx_driver$(EXE) test/rtpw$(EXE) \
	  test/dtls_srtp_driver$(EXE)

ifeq (1, $(HAVE_PCAP))
testapp += test/rtp_decoder$(EXE)
endif

$(testapp): libsrtp2.a

test/rtpw$(EXE): test/rtpw.c test/rtp.c test/util.c test/getopt_s.c \
        crypto/math/datatypes.c
	$(COMPILE) $(LDFLAGS) -o $@ $^ $(LIBS) $(SRTPLIB)

ifeq (1, $(HAVE_PCAP))
test/rtp_decoder$(EXE): test/rtp_decoder.c test/rtp.c test/util.c test/getopt_s.c \
        crypto/math/datatypes.c
	$(COMPILE) $(LDFLAGS) -o $@ $^ $(LIBS) $(SRTPLIB)
endif

crypto/test/aes_calc$(EXE): crypto/test/aes_calc.c test/util.c
	$(COMPILE) -I./test $(LDFLAGS) -o $@ $^ $(LIBS) $(SRTPLIB)

crypto/test/datatypes_driver$(EXE): crypto/test/datatypes_driver.c test/util.c
	$(COMPILE) -I./test $(LDFLAGS) -o $@ $^ $(LIBS) $(SRTPLIB)

crypto/test/sha1_driver$(EXE): crypto/test/sha1_driver.c test/util.c
	$(COMPILE) -I./test $(LDFLAGS) -o $@ $^ $(LIBS) $(SRTPLIB)

test/srtp_driver$(EXE): test/srtp_driver.c test/util.c test/getopt_s.c
	$(COMPILE) $(LDFLAGS) -o $@ $^ $(LIBS) $(SRTPLIB)

test/rdbx_driver$(EXE): test/rdbx_driver.c test/getopt_s.c
	$(COMPILE) $(LDFLAGS) -o $@ $^ $(LIBS) $(SRTPLIB)

test/dtls_srtp_driver$(EXE): test/dtls_srtp_driver.c test/getopt_s.c
	$(COMPILE) $(LDFLAGS) -o $@ $^ $(LIBS) $(SRTPLIB)

crypto/test/cipher_driver$(EXE): crypto/test/cipher_driver.c test/getopt_s.c
	$(COMPILE) $(LDFLAGS) -o $@ $^ $(LIBS) $(SRTPLIB)

crypto/test/kernel_driver$(EXE): crypto/test/kernel_driver.c test/getopt_s.c
	$(COMPILE) $(LDFLAGS) -o $@ $^ $(LIBS) $(SRTPLIB)

crypto/test/rand_gen$(EXE): crypto/test/rand_gen.c test/getopt_s.c
	$(COMPILE) $(LDFLAGS) -o $@ $^ $(LIBS) $(SRTPLIB)

crypto/test/rand_gen_soak$(EXE): crypto/test/rand_gen_soak.c test/getopt_s.c
	$(COMPILE) $(LDFLAGS) -o $@ $^ $(LIBS) $(SRTPLIB)

test: $(testapp)
	@echo "Build done. Please run '$(MAKE) runtest' to run self tests."

memtest: test/srtp_driver
	@test/srtp_driver -v -d "alloc" > tmp
	@grep freed tmp | wc -l > freed
	@grep allocated tmp | wc -l > allocated
	@echo "checking for memory leaks (only works with --enable-stdout)"
	cmp -s allocated freed
	@echo "passed (same number of alloc() and dealloc() calls found)"
	@rm freed allocated tmp

# the target 'plot' runs the timing test (test/srtp_driver -t) then
# uses gnuplot to produce plots of the results - see the script file
# 'timing'

plot:	test/srtp_driver
	test/srtp_driver -t > timing.dat


# bookkeeping: tags, clean, and distribution

tags:
	etags */*.[ch] */*/*.[ch] 


# documentation - the target libsrtpdoc builds a PDF file documenting
# libsrtp2

libsrtp2doc:
	$(MAKE) -C doc

.PHONY: clean superclean distclean install

install:
	$(INSTALL) -d $(DESTDIR)$(includedir)/srtp2
	$(INSTALL) -d $(DESTDIR)$(libdir)
	cp $(srcdir)/include/srtp.h $(DESTDIR)$(includedir)/srtp2  
	cp $(srcdir)/include/ekt.h $(DESTDIR)$(includedir)/srtp2  
	cp $(srcdir)/include/rtp.h $(DESTDIR)$(includedir)/srtp2  
	if [ -f libsrtp2.a ]; then cp libsrtp2.a $(DESTDIR)$(libdir)/; fi
	if [ -f libsrtp2.dll.a ]; then cp libsrtp2.dll.a $(DESTDIR)$(libdir)/; fi
	if [ -f libsrtp2.$(SHAREDLIBSUFFIX) ]; then \
		$(INSTALL) -d $(DESTDIR)$(SHAREDLIB_DIR); \
		cp libsrtp2.$(SHAREDLIBSUFFIX) $(DESTDIR)$(SHAREDLIB_DIR)/; \
		cp libsrtp2.$(SHAREDLIBSUFFIXNOVER) $(DESTDIR)$(SHAREDLIB_DIR)/; \
		ln -sfn libsrtp2.$(SHAREDLIBSUFFIX) $(DESTDIR)$(SHAREDLIB_DIR)/libsrtp2.$(SHAREDLIBSUFFIXNOVER); \
	fi
	if [ "$(pkgconfig_DATA)" != "" ]; then \
		$(INSTALL) -d $(DESTDIR)$(pkgconfigdir); \
		cp $(top_builddir)/$(pkgconfig_DATA) $(DESTDIR)$(pkgconfigdir)/; \
	fi

uninstall:
	rm -f $(DESTDIR)$(includedir)/srtp2/*.h
	rm -f $(DESTDIR)$(libdir)/libsrtp2.*
	-rmdir $(DESTDIR)$(includedir)/srtp2
	if [ "$(pkgconfig_DATA)" != "" ]; then \
		rm -f $(DESTDIR)$(pkgconfigdir)/$(pkgconfig_DATA); \
	fi

clean:
	rm -rf $(cryptobj) $(srtpobj) TAGS \
        libsrtp2.a libsrtp2.so libsrtp2.dll.a core *.core test/core
	for a in * */* */*/*; do			\
              if [ -f "$$a~" ] ; then rm -f $$a~; fi;	\
        done;
	for a in $(testapp); do rm -rf $$a$(EXE); done
	rm -rf *.pict *.jpg *.dat 
	rm -rf freed allocated tmp
	$(MAKE) -C doc clean

superclean: clean
	rm -rf crypto/include/config.h config.log config.cache config.status \
               Makefile crypto/Makefile doc/Makefile \
               .gdb_history test/.gdb_history .DS_Store
	rm -rf autom4te.cache

distclean: superclean

distname = libsrtp-$(shell cat VERSION)

distribution: runtest superclean 
	if ! [ -f VERSION ]; then exit 1; fi
	if [ -f ../$(distname).tgz ]; then               \
           mv ../$(distname).tgz ../$(distname).tgz.bak; \
        fi
	cd ..; tar cvzf $(distname).tgz libsrtp

# EOF
