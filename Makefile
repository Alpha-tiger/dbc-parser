CFLAGS:=-g3 -O0 -Wall -Wextra -Wformat -Wformat-security -Warray-bounds -Werror -fsanitize=leak $(shell pkg-config --cflags glib-2.0)
LDFLAGS:=-fsanitize=leak
LIBS=-llsan $(shell pkg-config --libs glib-2.0)

.PHONY: all test test-cantools fuzz clean

all: parse

#all: parser.png parser.html

test: parse test.dbc j1939_utf8.dbc VBOX3i_LDWS_VCI.DBC VBOX_lite.dbc SFP200%20v02.dbc
		./$< $(filter %.dbc,$^)

test-cantools: parse cantools
		./$< ./cantools/tests/files/dbc/*.dbc

fuzz: parse
		./fuzz.sh ./test.dbc

clean:
		-rm -f parse *.tab.c *.tab.h *.yy.c *.yy.h *.o *.png *.dot *.html *.xml *.output

.PRECIOUS: %.yy.c %.yy.h %.tab.c %.tab.h %.xml %.dot %.dbc

cantools:
		git clone https://github.com/eerimoq/cantools.git

j1939_utf8.dbc:
		wget -O $@ https://hackage.haskell.org/package/ecu-0.0.8/src/src/j1939_utf8.dbc

VBOX3i_LDWS_VCI.DBC:
		wget -O $@ http://www.vboxjapan.co.jp/ADAS/ADAS_LDWS/VBOX3i_LDWS_VCI.DBC

VBOX_lite.dbc:
		wget -O $@ http://www.racelogic.co.uk/_downloads/vbox/CAN_Database/VBOX_lite.dbc

SFP200%20v02.dbc:
		wget -O $@ http://www.sendyne.com/Datasheets/SFP200%20v02.dbc

scanner.yy.o: parser.tab.h

parse: scanner.yy.o parser.tab.o
		$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

%.yy.c %.yy.h: %.l
		flex --outfile=$*.yy.c --header-file=$*.yy.h  $<

%.tab.c %.tab.h %.xml: %.y
		bison -x -v -d $<

%.dot: %.xml
		xsltproc $(shell bison --print-datadir)/xslt/xml2dot.xsl $< >$@

%.html: %.xml
		xsltproc $(shell bison --print-datadir)/xslt/xml2xhtml.xsl $< >$@

%.png: %.dot
		dot -Tpng $< >$@
