LUA_DIR= /usr/local/share/lua/5.0
VERSION= 1.0.0
PKG= luaxmlrpc-$(VERSION)
DIST_DIR= $(PKG)
TAR_FILE= $(PKG).tar.gz
ZIP_FILE= $(PKG).zip
SRCS= README Makefile \
	src/xmlrpc.lua src/http.lua src/cgi.lua tests/test.lua \
	doc/us/index.html doc/us/manual.html doc/us/license.html doc/us/luaxmlrpc.png

dist: dist_dir
	tar -czf $(TAR_FILE) $(DIST_DIR)
	zip -rq $(ZIP_FILE) $(DIST_DIR)/*
	rm -rf $(DIST_DIR)

dist_dir:
	mkdir $(DIST_DIR)
	cp $(SRCS) $(DIST_DIR)

install:
	mkdir -p $(LUA_DIR)/xmlrpc
	cp src/xmlrpc.lua src/http.lua src/cgi.lua $(LUA_DIR)/xmlrpc

clean:
	rm -f $(TAR_FILE) $(ZIP_FILE)
