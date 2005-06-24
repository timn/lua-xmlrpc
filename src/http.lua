---------------------------------------------------------------------
-- XML-RPC over HTTP.
-- See Copyright Notice in license.html
-- $Id$
---------------------------------------------------------------------

require"socket.http"
require"ltn12"
require"xmlrpc"

local request = socket.http.request

module("xmlrpc.http")

---------------------------------------------------------------------
-- Call a remote method.
-- @param url String with the location of the server.
-- @param method String with the name of the method to be called.
-- @return Table with the response (could be a `fault' or a `params'
--	XML-RPC element).
---------------------------------------------------------------------
function call (url, method, ...)
	local request_sink, tbody = ltn12.sink.table()
	local request_body = xmlrpc.clEncode(method, unpack (arg))
	local err, code, headers, status = request {
		url = url,
		method = "POST",
		source = ltn12.source.string (request_body),
		sink = request_sink,
		headers = {
			["User-agent"] = "LuaXMLRPC",
			["Content-type"] = "text/xml",
			["content-length"] = tostring (string.len (request_body)),
		},
	}
	local body = table.concat (tbody)
	if tonumber (code) == 200 then
		return xmlrpc.clDecode (body)
	else
		error (tostring (err or code).."\n\n"..tostring(body))
	end
end
