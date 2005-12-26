require"xmlrpc"

---------------------------------------------------------------------
local function respond (resp)
	cgilua.header ("Date", os.date())
	cgilua.header ("Server", "Me")
	cgilua.header ("Content-length", string.len (resp))
	cgilua.header ("Connection", "close")
	cgilua.contentheader ("text", "xml")
	cgilua.put (resp)
end

---------------------------------------------------------------------
--[[
function assert (cond, msg)
	if not cond then
		respond (xmlrpc.srvEncode (
			{ code = 2, message = msg, },
			true
		))
		os.exit() -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	end
end
--]]
cgilua.seterroroutput (function (msg)
	respond (xmlrpc.srvEncode ({ code = 2, message = msg, }, true))
end)

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
local func, arg_table = decodedata (cgi[1])
local ok, result = callfunc (func, arg_table)
local r = xmlrpc.srvEncode (result, not ok)
respond (r)
