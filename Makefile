VERSION=0.1

prefix=/usr
bindir=$(prefix)/bin
datadir=$(prefix)/share/depanneur
libdir=$(prefix)/lib
sudodir=/etc/sudoers.d
DESTDIR=

all:

install:
	install -m755 -d \
	    $(DESTDIR)$(bindir)
	install -m755 -d \
	    $(DESTDIR)$(datadir)
	install -m755 \
	    depanneur  \
	    $(DESTDIR)$(bindir)
	install -m750 -d \
	    $(DESTDIR)$(sudodir)
	install -m440 \
        data/gbs \
        $(DESTDIR)$(sudodir)
	install -m644 \
        data/build-report.tmpl \
        $(DESTDIR)$(datadir)/
	install -m644 \
        data/not-export \
        $(DESTDIR)$(datadir)/
