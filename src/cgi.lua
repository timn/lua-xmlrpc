#!/usr/local/bin/lua50
-- See Copyright Notice in license.html
-- $Id$

SAPI = {
	Request = {},
	Response = {},
	Info = { -- Information data
		_COPYRIGHT = "Copyright (C) 2004-2005 Kepler Project",
		_DESCRIPTION = "CGI SAPI implementation",
		_VERSION = "1.0",
		ispersistent = false,
	},
}
	-- Headers
	SAPI.Response.contenttype = function (s)
		io.stdout:write ("Content-type: "..s.."\n\n")
	end
	SAPI.Response.redirect = function (s)
		io.stdout:write ("Location: "..s.."\n\n")
	end
	SAPI.Response.header = function (h, v)
		io.stdout:write (string.format ("%s: %s\n", h, v))
	end
	-- Contents
	SAPI.Response.write = function (s) io.stdout:write (s) end
	SAPI.Response.errorlog = function (s) io.stderr:write (s) end
	-- Input POST data
	SAPI.Request.getpostdata = function (n) return io.stdin:read (n) end
	-- Input general information
	SAPI.Request.servervariable = function (n) return os.getenv(n) end

if string.find(_VERSION, "Lua 5.0.2") and not _COMPAT51 then
	local root = "/usr/local/share/lua/5.0/"
	LUA_PATH = root.."?.lua;"..root.."?/init.lua;"..root.."?/?.lua"
	require"compat-5.1"
	root = "/usr/local/lib/lua/5.0/"
	package.cpath = root.."?.so;"..root.."l?.so"
end

require"xmlrpc"
require"cgilua.post"

---------------------------------------------------------------------
local function respond (resp)
	SAPI.Response.header ("Date", os.date())
	SAPI.Response.header ("Server", "Me")
	SAPI.Response.header ("Content-length", string.len (resp))
	SAPI.Response.header ("Connection", "close")
	SAPI.Response.contenttype ("text/xml")
	SAPI.Response.write (resp)
end

---------------------------------------------------------------------
local _assert = assert
function assert (cond, msg)
	if not cond then
		respond (xmlrpc.srvEncode (
			{ code = 2, message = msg, },
			true
		))
		os.exit() -- !!!!!!!!!!!
	end
end

---------------------------------------------------------------------
local function getdata ()
	local doc = {}
	cgilua.post.parsedata {
		read = SAPI.Request.getpostdata,
		discardinput = nil,
		content_type = SAPI.Request.servervariable"CONTENT_TYPE",
		content_length = SAPI.Request.servervariable"CONTENT_LENGTH",
		maxinput = 2 * 1024 * 1024,
		maxfilesize = 1024 * 1024,
		args = doc,
	}
	return doc[1]
end

---------------------------------------------------------------------
local function decodedata (doc)
	local method, arg_table = xmlrpc.srvDecode (doc)
	assert (type(method) == "string", "Invalid `method': string expected")
	local t = type(arg_table)
	assert (t == "table" or t == "nil", "Invalid table of arguments: not a table nor nil")

	local func = xmlrpc.dispatch (method)
	assert (type(func) == "function", "Unavailable method")

	return func, (arg_table or {})
end

---------------------------------------------------------------------
local function callfunc (func, arg_table)
	local result = { pcall (func, unpack (arg_table)) }
	local ok = result[1]
	if not ok then
		result = { code = 3, message = result[2], }
	else
		table.remove (result, 1)
		if table.getn (result) == 1 then
			result = result[1]
		end
	end
	return ok, result
end

---------------------------------------------------------------------
local kepler_home = "http://www.keplerproject.org"
local kepler_products = { "luasql", "lualdap", "luaexpat", "luaxmlrpc", }
local kepler_sites = {
	luasql = kepler_home.."/luasql",
	lualdap = kepler_home.."/lualdap",
	luaexpat = kepler_home.."/luaexpat",
	luaxmlrpc = kepler_home.."/luaxmlrpc",
}

local __methods
__methods = {
	system = {
		listMethods = function (self)
			local l = {}
			for name, obj in pairs (__methods) do
				for method in pairs (obj) do
					table.insert (l, name.."."..method)
				end
			end
			return l
		end,
	},
	kepler = {
		products = function (self) return kepler_products end,
		site = function (self, prod) return kepler_sites[prod] end,
	},
}

---------------------------------------------------------------------
-- Main
---------------------------------------------------------------------

xmlrpc.srvMethods (__methods)
local doc = getdata ()
local func, arg_table = decodedata (doc)
local ok, result = callfunc (func, arg_table)
local r = xmlrpc.srvEncode (result, not ok)
respond (r)
