-- See Copyright Notice in license.html
-- $Id$

require"xmlrpc"

---------------------------------------------------------------------
function respond (resp)
	io.stdout:write (string.format ([[Date: %s
Server: Me
Content-Type: text/xml
Content-Length: %d
Connection: close

%s
]], os.date(), string.len(resp), resp))
end

---------------------------------------------------------------------
local _assert = assert
function assert (cond, msg)
	if not cond then
		respond (xmlrpc.server_encode (
			{ code = 2, message = msg, },
			true
		))
		os.exit() -- !!!!!!!!!!!
	end
end

---------------------------------------------------------------------
-- Main
---------------------------------------------------------------------

local kepler_home = "http://www.keplerproject.org"
local kepler_products = { "luasql", "lualdap", "luaexpat", "luaxmlrpc", }
local kepler_sites = {
	luasql = kepler_home.."/luasql",
	lualdap = kepler_home.."/lualdap",
	luaexpat = kepler_home.."/luaexpat",
	luaxmlrpc = kepler_home.."/luaxmlrpc",
}

xmlrpc.server_methods {
	system = {
		listMethods = function () return { "system.listMethods" } end,
	},
	kepler = {
		products = function () return kepler_products end,
		site = function (prod) return kepler_sites[prod] end,
	},
}

local doc = {}
post.parsedata (doc)

local method, arg_table = xmlrpc.server_decode (doc[1])
assert (type(method) == "string", "Invalid `method': string expected")
local t = type(arg_table)
assert (t == "table" or t == "nil", "Invalid table of arguments: not a table nor nil")

local func = xmlrpc.dispatch (method)
assert (type(func) == "function", "Unavailable method")

local result = { pcall (func, unpack (arg_table or {})) }

local ok = result[1]
if not ok then
	result = { code = 3, message = result[2], }
else
	table.remove (result, 1)
	if table.getn (result) == 1 then
		result = result[1]
	end
end

local r = xmlrpc.server_encode (result, not ok)
respond (r)
