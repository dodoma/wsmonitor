#!/usr/local/bin/lua

zlib = require("zlib")

zlibPrefix = "\x78\x9c"
deflatePostfix = "\x00\x00\xff\xff"

function string.fromhex(str)
    return (string.gsub(str, '..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

function string.tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end

function _request_string(sendrequest)
   if (sendrequest) then return "===>"
   else return "<==="
   end
end

function _opstring(opcode)
   if opcode == 0 then return "stream"
   elseif opcode == 1 then return "text"
   elseif opcode == 2 then return "binary"
   elseif opcode == 8 then return "close"
   elseif opcode == 9 then return "ping"
   elseif opcode == 10 then return "pong"
   else return "unknown"
   end
end

function _deflate(data)
   zpackets = zpackets .. data .. deflatePostfix

   --print(string.len(zpackets) .. "xxxxxxxxxx" .. string.tohex(zpackets))
   local inflateStream = zlib.inflate()
   if unexpected_condition then print("error!") end
   local unzipped = inflateStream(zlibPrefix .. zpackets)
   local thismsg = string.sub(unzipped, string.len(upackets) + 1)
   upackets = unzipped

   return thismsg
end



function parse_websocket(msg)
   pos = 1
   val = tonumber(string.sub(msg, pos, 2), 16)

   finish = true
   if (val & tonumber("80", 16) == 0) then finish = false end
   zipped = true
   if (val & tonumber("40", 16) == 0) then zipped = false end
   opcode = val & tonumber("f", 16)

   pos = pos + 2
   val = tonumber(string.sub(msg, pos, pos + 1), 16)

   -- print("xxxx" .. pos .. string.sub(msg, pos, pos + 2))
   masked = true
   if (val & tonumber("80", 16) == 0) then masked = false end
   payloadsize = val & tonumber("7f", 16)

   pos = pos + 2
   if (payloadsize == 126) then
      val = tonumber(string.sub(msg, pos, pos + 3), 16)
      --payloadsize = tls.ntohs(val)
      payloadsize = val
      ---print("yyyyy"..val..payloadsize)
      pos = pos + 4
   elseif (paylaodsize == 127) then
      val = tonumber(string.sub(msg, pos, pos + 15), 16)
      --payloadsize = tls.ntohll(val)
      pos = pos + 16
   end

   outstr = os.date("%Y-%m-%d %H:%M:%S ")
   if (finish) then outstr = outstr .. "FIN" else outstr = outstr .. "UNFIN" end
   if (zipped) then outstr = outstr .. " " .. "ZIPPED" else outstr = outstr .. " " .. "RAW" end
   outstr = outstr .. " " .. _opstring(opcode)
   if (masked) then outstr = outstr .. " " .. "MASKED" else outstr = outstr .. " " .. "UNMASKED" end
   outstr = outstr .. " " .. payloadsize .. " "

   resultstr = ""
   if (masked) then
      mask = {}
      mask[1] = tonumber(string.sub(msg, pos, pos + 1), 16)
      mask[2] = tonumber(string.sub(msg, pos + 2, pos + 2 + 1), 16)
      mask[3] = tonumber(string.sub(msg, pos + 4, pos + 4 + 1), 16)
      mask[4] = tonumber(string.sub(msg, pos + 6, pos + 6 + 1), 16)
      pos = pos + 8

      --print(payloadsize .. " yyy " .. pos .. string.sub(msg, pos))
      for i = 1, payloadsize do
         val = tonumber(string.sub(msg, pos, pos + 1), 16)
         index = i % 4
         if (index == 0) then index = 4 end
         resultstr = resultstr .. string.char(val ~ mask[index])

         pos = pos + 2
      end
   else
      resultstr = string.fromhex(string.sub(msg, pos))
   end

   if (zipped) then resultstr = _deflate(resultstr) end

   local suppress = os.getenv("WSMONITOR_SUPPRESS")
   if (not suppress or not string.find(resultstr, suppress)) then
      print(outstr .. "\t" .. _request_string(sendrequest))
      print(resultstr .. "\n")
   end
end

zpackets = ""
upackets = ""
sendrequest = true

for hexstring in io.lines() do
   --print("解析" .. hexstring)
   if (hexstring == '__RSV0__') then sendrequest = true
   elseif (hexstring == '__RSV1__') then sendrequest = false
   elseif (string.find(hexstring, "^485454502f312e31")) then -- HTTP/1.1
      print(_request_string(sendrequest))
      print(string.fromhex(hexstring))
   elseif (string.find(hexstring, "0d0a0d0a$")) then -- \r\n\r\n
      print(_request_string(sendrequest))
      print(string.fromhex(hexstring))
   elseif (string.len(hexstring) > 0) then
      parse_websocket(hexstring)
   end
end
