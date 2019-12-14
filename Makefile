CC ?= gcc
CFLAGS += -Wall -I. -fPIC
PREFIX ?= $(DESTDIR)/usr/local
TESTS = $(patsubst %.c, %, $(wildcard t/*.c))
LIB_EXT = .a
OBJ_EXT = .o
SO = so
LDDLFLAGS = 

ifdef ANSI
	# -D_BSD_SOURCE for MAP_ANONYMOUS
	CFLAGS += -ansi -D_BSD_SOURCE
	LDLIBS += -lbsd-compat
endif

ifdef WINDOWS
    SO = dll
	CC = x86_64-w64-mingw32-gcc
    LDDLFLAGS += -Wl,--enable-auto-image-base -Xlinker --out-implib -Xlinker libtap.dll.a
endif

%:
	$(CC) $(LDFLAGS) $(TARGET_ARCH) $(filter %.o %.a %.so, $^) $(LDLIBS) -o $@

%.o:
	$(CC) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c $(filter %.c, $^) $(LDLIBS) -o $@

%.a:
	$(AR) rcs $@ $(filter %.o, $^)

%.$(SO):
	$(CC) -shared $(LDFLAGS) $(LDDLFLAGS) $(TARGET_ARCH) $(filter %.o, $^) $(LDLIBS) -o $@

all: libtap.a libtap.$(SO) tap.pc tests

tap.pc:
	@echo generating tap.pc
	@echo 'prefix='$(PREFIX) > tap.pc
	@echo 'exec_prefix=$${prefix}' >> tap.pc
	@echo 'libdir=$${prefix}/lib' >> tap.pc
	@echo 'includedir=$${prefix}/include' >> tap.pc
	@echo '' >> tap.pc
	@echo 'Name: libtap' >> tap.pc
	@echo 'Description: Write tests in C' >> tap.pc
	@echo 'Version: 0.1.0' >> tap.pc
	@echo 'URL: https://github.com/zorgnax/libtap' >> tap.pc
	@echo 'Libs: -L$${libdir} -ltap' >> tap.pc
	@echo 'Cflags: -I$${includedir}' >> tap.pc

libtap.a: tap.o

libtap.$(SO): tap.o

tap.o: tap.c tap.h

tests: $(TESTS)

$(TESTS): %: %.o libtap.a

$(patsubst %, %.o, $(TESTS)): %.o: %.c tap.h

clean:
	rm -rf *.o t/*.o tap.pc libtap.a libtap.$(SO) libtap.$(SO).a $(TESTS)

install: libtap.a tap.h libtap.$(SO) tap.pc
	mkdir -p $(PREFIX)/lib $(PREFIX)/include $(PREFIX)/lib/pkgconfig
	install -c libtap.a $(PREFIX)/lib
	install -c libtap.$(SO) $(PREFIX)/lib
ifdef WINDOWS
	install -c libtap.$(SO).a $(PREFIX)/lib
endif
	install -c tap.pc $(PREFIX)/lib/pkgconfig
	install -c tap.h $(PREFIX)/include

uninstall:
	rm $(PREFIX)/lib/libtap.a $(PREFIX)/lib/libtap.$(SO) $(PREFIX)/include/tap.h
ifdef WINDOWS
	rm $(PREFIX)/lib/libtap.$(SO).a
endif

dist:
	rm libtap.zip
	zip -r libtap *

check test: all
	./t/test

.PHONY: all clean install uninstall dist check test tests
