#!/usr/local/bin/lua.5.0
-- See Copyright Notice in license.html

require "xmlrpc"
require "xrh"

function table.print (tab, indent, spacing)
	spacing = spacing or ""
	indent = indent or "\t"
    io.write ("{\n")
    for nome, val in pairs (tab) do
        io.write (spacing..indent)
        local t = type(nome)
		if t == "string" then
            io.write (string.format ("[%q] = ", tostring (nome)))
		elseif t == "number" or t == "boolean" then
            io.write (string.format ("[%s] = ", tostring (nome)))
        else
            io.write (t)
        end
        t = type(val)
        if t == "string" or t == "number" then
            io.write (string.format ("%q", val))
        elseif t == "table" then
            table.print (val, indent, spacing..indent)
        else
            io.write (t)
        end
        io.write (",\n")
    end
    io.write (spacing.."}")
end

function table.equal (t1, t2)
	if type(t1) ~= "table" or type(t2) ~= "table" then
		return false
	end
	for key, v1 in t1 do
		local v2 = rawget (t2, key)
		if type(v1) == "table" and type(v2) == "table" then
			if not table.equal (v1, v2) then
				return false
			end
		elseif v1 ~= v2 then
			return false
		end
	end
	return true
end

function call_test (xml_call, method, ...)
	local xc = string.gsub (xml_call, "(%p)", "%%%1")
	xc = string.gsub (xc, "\r?\n%s*", "%%s*")
	arg.n = nil

	-- client enconding test
	local meth_call = xmlrpc.client_encode (method, unpack (arg))
	local s = string.gsub (meth_call, xc, "")
	s = string.gsub (s, "%s*", "")
	assert (s == "", s)

	-- server decoding test
	local meth_call, param = xmlrpc.server_decode (xml_call)
	assert (meth_call == method, meth_call)
	assert (table.equal (arg, param))
end

function response_test (xml_resp, lua_obj)
	-- client decoding test
	local ok, obj = xmlrpc.client_decode (xml_resp)
	if type (obj) == "table" then
		assert (table.equal (obj, lua_obj))
	else
		assert (obj == lua_obj)
	end

	-- server encoding test
	xml_resp = string.gsub (xml_resp, "(%p)", "%%%1")
	xml_resp = string.gsub (xml_resp, "\r?\n%s*", "%%s*")
	local meth_resp = xmlrpc.server_encode (lua_obj)
	local s = string.gsub (meth_resp, xml_resp, "")
	s = string.gsub (s, "%s*", "")
	assert (s == "", s)
end

function fault_test (xml_resp, message, code)
	-- client decoding test
	local ok, str, n = xmlrpc.client_decode (xml_resp)
	assert (str == message)
	assert (n == code)

	-- server encoding test
	xml_resp = string.gsub (xml_resp, "(%p)", "%%%1")
	xml_resp = string.gsub (xml_resp, "\r?\n%s*", "%%s*")
	local meth_resp = xmlrpc.server_encode ({ message = message, code = code }, true)
	local s = string.gsub (meth_resp, xml_resp, "")
	s = string.gsub (s, "%s*", "")
if s ~= "" then
print(meth_resp,"!!!",xml_resp)
end
	assert (s == "", s)
end

---------------------------------------------------------------------
-- call tests.
---------------------------------------------------------------------
call_test ([[<?xml version="1.0"?>
<methodCall>
   <methodName>examples.getStateName</methodName>
   <params>
      <param>
         <value><int>41</int></value>
         </param>
      </params>
   </methodCall>]], "examples.getStateName", 41)

call_test ([[<?xml version="1.0"?>
<methodCall>
   <methodName>examples.getSomething</methodName>
   <params>
      <param>
         <value>
<struct>
   <member>
      <name>lowerBound</name>
      <value><int>18</int></value>
      </member>
   <member>
      <name>upperBound</name>
      <value><int>139</int></value>
      </member>
   </struct>
           </value>
         </param>
      </params>
   </methodCall>]], "examples.getSomething", { lowerBound = 18, upperBound = 139 })

--[[
call_test ([[<?xml version="1.0"?>
<methodCall>
  <methodName>insertTable</methodName>
  <params>
    <param><value><string>people</string></value></param>
    <param><value>
      <array><data>
        <value>
          <struct>
            <member>
              <name>name</name>
              <value><string>Fulano</string></value>
            </member>
            <member>
              <name>email</name>
              <value><string>fulano@nowhere.world</string></value>
            </member>
          </struct>
        </value>
        <value>
          <struct>
            <member>
              <name>name</name>
              <value><string>Beltrano</string></value>
            </member>
            <member>
              <name>email</name>
              <value><string>beltrano@nowhere.world</string></value>
            </member>
          </struct>
        </value>
        <value>
          <struct>
            <member>
              <name>name</name>
              <value><string>Cicrano</string></value>
            </member>
            <member>
              <name>email</name>
              <value><string>cicrano@nowhere.world</string></value>
            </member>
          </struct>
        </value>
      </data></array>
    </value></param> 
  </params>
</methodCall>]],
	"insertTable",
	{
		{ name = "Fulano", email = "fulano@nowhere.world", },
		{ name = "Beltrano", email = "beltrano@nowhere.world", },
		{ name = "Cicrano", email = "cicrano@nowhere.world", },
	})
--]]

---------------------------------------------------------------------
-- response tests.
---------------------------------------------------------------------
response_test ([[<?xml version="1.0"?>
<methodResponse>
   <params>
      <param>
         <value><string>South Dakota</string></value>
         </param>
      </params>
   </methodResponse>]], "South Dakota")

response_test ([[<?xml version="1.0"?>
<methodResponse>
   <params>
      <param>
         <value>
<struct>
   <member>
      <name>lowerBound</name>
      <value><int>18</int></value>
      </member>
   <member>
      <name>upperBound</name>
      <value><int>139</int></value>
      </member>
   </struct>
           </value>
         </param>
      </params>
   </methodResponse>]], { lowerBound = 18, upperBound = 139 })

fault_test ([[<?xml version="1.0"?>
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
            <value><string>error string</string></value>
          </member>
        </struct>
      </value>
    </fault>
</methodResponse>]], "error string", 1)
