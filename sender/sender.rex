/*
 Copyright © 2019 Guy M. Allard

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http:www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

-- Get network socket
asock = .netconn~open(.nil)

-- Get CONNECT headers
stp = value("STOMP_PROTOCOL", "", .stc~env)
select
    when stp == .stc~SPL_10 then do
        ch = .headers~connhdr10
    end
    when stp == .stc~SPL_11 then do
        ch = .headers~connhdr11
    end
    when stp == .stc~SPL_12 then do
        ch = .headers~connhdr12
    end
    otherwise do
        ch = .headers~connhdr12
    end
end

-- Empty options directory
cod = .directory~new

-- Get a STOMPRX connection
sc = .connection~new(asock, ch, cod)

-- Check for a good CONNECT
if sc~connframe~command <> .stc~CONNECTED then do
    sc~connframe~pp("CONNECT Error:")
    exit
end
--
startmsg = 1
t = value("STOMP_NMSGS", "", .stc~env)
nmsgs = 1
if t <> "" then nmsgs = t
t = value("STOMP_DEST", "", .stc~env)
if t = "" then dest = "/queue/rexx.send.receive"
else dest = t
say "NMSGS:" nmsgs
say "DEST:" dest

-- Pattern headers for ~send
sh = .headers~new
t = .header~new(.stc~HK_DESTINATION, dest)
sh~add(t)
t = .header~new(.stc~HK_CONTENT_TYPE, "text/plain; charset=UTF-8")
sh~add(t)

-- To make messages somewhat variable
rpart = "12345678901234567890"

-- Start SENDs
say "send demo starts"
mc = 0
do i = startmsg to nmsgs
    mc = mc + 1                         -- Bump message count
    rp = rpart~substr(1, random(1,20))  -- Random part of the message

    -- Create a message
    om = "Message" i rp
    say "send test message->" "Count:" i "Length:" om~length "Message:" om

    -- Clone pattern headers and update the clone
    useh = sh~clone -- clone pattern
    t = .header~new(.stc~HK_CONTENT_LENGTH, om~length)
    useh~add(t)    
    t = .header~new("srx_mid", mc) -- A user header
    useh~add(t)    
    -- useh~pp("Send Headers App:")

    -- Call SEND API
    rc = sc~send(useh, om)
    if rc < 0 then do
        say "send failed:" rc
        exit
    end

    -- Check if broker sent an ERROR frame
    ef = sc~recverr
    if ef <> .nil then do
        say "error frame received from broker"
        ef~pp("ERROR Frame is:")
        sc~disconnect
        exit
    end
    
end

-- DISCONNECT and exit
dh = .headers~new
rc = .header~new(.stc~HK_RECEIPT, "send.receipt.id")
dh~add(rc)
sc~disconnect(dh)
rf = sc~recvrcpt(0.3)
rf~pp("RECEIPT Frame:")

--
say "send demo done"
exit

--
::requires "../base.rex"
