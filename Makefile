
DESTDIR=/usr/local
PREFIX=mbedtls_
OLDPREFIX=polarssl_

all:	lib programs tests

no_test:	programs

programs:
ifndef SKIP_PROGRAMS
	$(MAKE) -C programs
endif

lib:
	$(MAKE) -C library

tests:
ifndef SKIP_TESTS
	$(MAKE) -C tests
endif

install:
	mkdir -p $(DESTDIR)/include/polarssl
	cp -r include/polarssl $(DESTDIR)/include
	
	mkdir -p $(DESTDIR)/lib
#	cp library/libpolarssl.* library/libmbedtls.* $(DESTDIR)/lib
	cp -a library/*.a library/*.so library/*.so.* $(DESTDIR)/lib
	
ifndef SKIP_PROGRAMS
	mkdir -p $(DESTDIR)/bin
	for p in programs/*/* ; do              \
	    if [ -x $$p ] && [ ! -d $$p ] ;     \
	    then                                \
	        f=$(PREFIX)`basename $$p` ;     \
	        o=$(OLDPREFIX)`basename $$p` ;  \
	        cp $$p $(DESTDIR)/bin/$$f ;     \
	        ln -sf $$f $(DESTDIR)/bin/$$o ; \
	    fi                                  \
	done
endif

uninstall:
	rm -rf $(DESTDIR)/include/polarssl
	rm -f $(DESTDIR)/lib/libpolarssl.*
	rm -f $(DESTDIR)/lib/libmbedtls.*
	
ifndef SKIP_PROGRAMS
	for p in programs/*/* ; do              \
	    if [ -x $$p ] && [ ! -d $$p ] ;     \
	    then                                \
	        f=$(PREFIX)`basename $$p` ;     \
	        o=$(OLDPREFIX)`basename $$p` ;  \
	        rm -f $(DESTDIR)/bin/$$f ;      \
	        rm -f $(DESTDIR)/bin/$$o ;      \
	    fi                                  \
	done
endif

clean:
	$(MAKE) -C library clean
ifndef SKIP_PROGRAMS
	$(MAKE) -C programs clean
endif
	$(MAKE) -C tests clean
	find . \( -name \*.gcno -o -name \*.gcda -o -name *.info \) -exec rm {} +

check: tests
	$(MAKE) -C tests check

test-ref-configs:
	tests/scripts/test-ref-configs.pl

# note: for coverage testing, build with:
# CFLAGS='--coverage' make OFLAGS='-g3 -O0'
covtest:
	make check
	programs/test/selftest
	( cd tests && ./compat.sh )
	( cd tests && ./ssl-opt.sh )

lcov:
	rm -rf Coverage
	lcov --capture --initial --directory library -o files.info
	lcov --capture --directory library -o tests.info
	lcov --add-tracefile files.info --add-tracefile tests.info -o all.info
	lcov --remove all.info -o final.info '*.h'
	gendesc tests/Descriptions.txt -o descriptions
	genhtml --title "mbed TLS" --description-file descriptions --keep-descriptions --legend --no-branch-coverage -o Coverage final.info
	rm -f files.info tests.info all.info final.info descriptions

apidoc:
	mkdir -p apidoc
	doxygen doxygen/mbedtls.doxyfile

apidoc_clean:
	if [ -d apidoc ] ;			\
	then				    	\
		rm -rf apidoc ;			\
	fi
