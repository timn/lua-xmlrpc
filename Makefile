VERSION= 1.0a
PKG= luaxmlrpc-$(VERSION)
DIST_DIR= $(PKG)
TAR_FILE= $(PKG).tar.gz
ZIP_FILE= $(PKG).zip
SRCS= README Makefile \
	xmlrpc.lua http.lua cgi.lua test.lua \
	index.html manual.html license.html luaxmlrpc.png

dist: dist_dir
	tar -czf $(TAR_FILE) $(DIST_DIR)
	zip -lq $(ZIP_FILE) $(DIST_DIR)/*
	rm -rf $(DIST_DIR)

dist_dir:
	mkdir $(DIST_DIR)
	cp $(SRCS) $(DIST_DIR)

clean:
	rm $(TAR_FILE) $(ZIP_FILE)
