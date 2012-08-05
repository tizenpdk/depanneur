VERSION=0.1

prefix=/usr
bindir=$(prefix)/bin
datadir=$(prefix)/share
libdir=$(prefix)/lib
sysconfdir=/etc
DESTDIR=

all:

install:
	install -m755 -d \
	    $(DESTDIR)$(bindir)
	install -m755 \
	    depanneur  \
		build_wrapper \
	    $(DESTDIR)$(bindir)

