---------------------------------------------------------------------
-- XML-RPC over HTTP.
-- See Copyright Notice in license.html
-- $Id$
---------------------------------------------------------------------

require"luasocket"
require"xmlrpc"

local post = socket.http.post

xrh = {}

---------------------------------------------------------------------
-- Call a remote method.
-- @param url String with the location of the server.
-- @param method String with the name of the method to be called.
-- @return Table with the response (could be a `fault' or a `params'
--	XML-RPC element).
---------------------------------------------------------------------
function xrh.call (url, method, ...)
	local body, headers, code, err = post {
		url = url,
		body = xmlrpc.client_encode (method, unpack (arg)),
		headers = {
			["User-agent"] = "LuaXMLRPC",
			["Content-type"] = "text/xml",
		},
	}
	if tonumber (code) == 200 then
		return xmlrpc.client_decode (body)
	else
		error (err or code)
	end
end

---------------------------------------------------------------------
---------------------------------------------------------------------
local clients = {}
local send_clients = {}
function xrh.serve (methods)
	local s = assert (socket.bind ("localhost", "8080"))
	s:settimeout (.01)
	while true do
		-- look for new clients
		local client = s:accept ()
		if client then
			client:settimeout (1)
			table.insert (clients, client)
		end
		-- receiving clients
		local rec_cli, _, err = socket.select (clients, nil, .01)
		if err and err ~= "timeout" then
			print ("!!", err)
		end
		if rec_cli then
			-- process requests
			for i, cli in rec_cli do
				local data, err = cli:receive()
				if err then
					print ("!!", err, "(",cli,")")
					table.remove (clients, i) -- !!!!!!!!!!!!!!!!
				else
					local resp = [[<?xml version="1.0"?>
<methodResponse>
  <fault>
    <value>
      <struct>
        <member>
          <name>faultCode</name>
          <value><int>1</int></value>
        </member>
        <member>
          <name>faultString</name>
          <value><string>Still debugging</string></value>
        </member>
      </struct>
    </value>
  </fault>
</methodResponse>]]
					local err, n = cli:send (string.format ([[HTTP/1.1 200 OK
Date: %s
Server: Me
Content-Type: text/xml
Content-Length: %d
Connection: close

%s
]], os.date(), string.len(resp), resp))

print (">>", n, "(",string.len(resp),")")
					cli:close()
					table.remove (clients, i)
				end
			end
		end
	end
end

function eca ()
	local c = assert (s:accept ())
	local req = {}
	-- headers
	local r, err
	repeat
		r, err = c:receive ()
print(">>", '['..r..']', err, r=='') io.flush()
		table.insert (req, r)
	until r == ""
print(">>", table.concat(req)) io.flush()
	local err, n = c:send [[HTTP/1.1 200 OK
Connection: close
Content-Length: 158
Content-Type: text/xml

<?xml version="1.0"?>
<methodResponse>
	<params>
		<param>
			<value><string>South Dakota</string></value>
			</param>
		</params>
	</methodResponse>]]

	repeat
		r, err = c:receive ()
print(">>", '['..r..']', err, r=='') io.flush()
		table.insert (req, r)
	until r == ""

--[[
	while not err do
print(">>", '['..req..']', err, req=='') io.flush()
		req, err = c:receive ()
	end
--]]
end
