-- See Copyright Notice in license.html
require"xmlrpc"

local _assert = assert
function assert (cond, msg)
	if not cond then
		io.stdout:write (xmlrpc.server_encode (
			{ code = 2, message = msg, },
			true
		))
		os.exit() -- !!!!!!!!!!!
	end
end

local doc = parsepostdata ()

local method, arg_table = xmlrpc.server_decode (doc)
assert (type(method) == "string")
assert (type(arg_table) == "table")

local func = xmlrpc.dispatch (method)
assert (type(func) == "function")

local result = { pcall (func, unpack (arg_table)) }

local ok = result[1]
tremove (result, 1)
if not ok then
	result = { code = 3, message = result[2], }
end

io.stdout:write (xmlrpc.server_encode (result, not ok))
