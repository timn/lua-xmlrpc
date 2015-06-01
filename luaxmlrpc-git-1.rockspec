 package = "luaxmlrpc"
 version = "git-1"
 source = {
    url = "git://github.com/timn/lua-xmlrpc",
    tag = "master",
 }
 description = {
    summary = "Allows to access and provide XML-RPC services",
    detailed = [[
        This package provides code to access XML-RPC services over HTTP. It also
        provides code to provide these services, e.g. by using Xavante.
        License: http://keplerproject.github.io/lua-xmlrpc/license.html
    ]],
    homepage = "http://keplerproject.github.io/lua-xmlrpc",
    license = "GPL-compatible"
 }
 dependencies = {
    "lua >= 5.1, < 5.3",
    "luaexpat",
    "luasocket"
 }
 build = {
    type = "builtin",
    modules = {
       ["xmlrpc.init"] = "src/init.lua",
       ["xmlrpc.http"] = "src/http.lua",
       ["xmlrpc.server"] = "src/server.lua"
    },
    copy_directories = { "doc", "examples", "tests" }
 }
 
