VERSION=0.1

prefix=/usr
bindir=$(prefix)/bin
datadir=$(prefix)/share
libdir=$(prefix)/lib
sudodir=/etc/sudoers.d
DESTDIR=

all:

install:
	install -m755 -d \
	    $(DESTDIR)$(bindir)
	install -m755 \
	    depanneur  \
	    $(DESTDIR)$(bindir)
	install -m750 -d \
	    $(DESTDIR)$(sudodir)
	install -m440 \
        data/gbs \
        $(DESTDIR)$(sudodir)

