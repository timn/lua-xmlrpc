# $Id$

LUA_DIR= /usr/local/share/lua/5.0

LUAS= src/xmlrpc.lua src/http.lua src/server.lua


build clean:

install:
	mkdir -p $(LUA_DIR)/xmlrpc
	cp $(LUAS) $(LUA_DIR)/xmlrpc
