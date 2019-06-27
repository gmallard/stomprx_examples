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
say "Protocol Level:" sc~protocol
--
startmsg = 1
t = value("STOMP_NMSGS", "", .stc~env)
nmsgs = 1
if t <> "" then nmsgs = t
t = value("STOMP_DEST", "", .stc~env)
if t = "" then dest = "/queue/rexx.send.receive"
else dest = t
say "NMSGS:" nmsgs time("L")
say "DEST:" dest time("L")

--
sunh1 = .headers~new
desth = .header~new(.stc~HK_DESTINATION, dest)
sunh1~add(desth)
id = "recv_12"
idh = .header~new(.stc~HK_ID, id)
sunh1~add(idh)
sunh1~pp("recv12 Headers 12:")

-- Subscription specific queue
subq = .queue~new

-- SUBSCRIBE to the DESTINATION
-- This SUBSCRIBE does specify a subscription specific message queue.
-- MESSAGE frames will be placed on this message queue.
-- Call "pull" to get messages from this queue (as shown below).
src = sc~subscribe(sunh1, subq)
say "recv12 subscribe rc is" src time("L")


-- Start receives
say "receive demo starts" time("L")
mc = 0
lc = 0
do until mc >= nmsgs
    lc = lc + 1
    say "Start next receive loop" lc time("L")

    -- Handle any errors
    aframe = sc~recverr
    if aframe <> .nil then do
        aframe~pp("ERROR Frame from broker:")
        sc~shutdowwn
        exit
    end

    -- Handle (unexpected here) RECEIPTs
    aframe = sc~recvrcpt
    if aframe <> .nil then do
        aframe~pp("Unexpected RECEIPT Frame from broker:")
        iterate
    end

    -- Get from the subscription specific message queue
    aframe = subq~pull
    if aframe == .nil then do
        call SysSleep 0.2
        iterate
    end
    aframe~pp("MESSAGE From Broker:")
    mc = mc + 1

end

-- UNSUBSCRIBE
urc = sc~unsubscribe(sunh1)
say "recv12 unsubscribe rc is" urc time("L")

-- DISCONNECT and exit
dh = .headers~new
rc = .header~new(.stc~HK_RECEIPT, "receive.receipt.id")
dh~add(rc)
sc~disconnect(dh)
rf = sc~recvrcpt(0.3)
rf~pp("RECEIPT Frame:")

exit

--
::requires "../../base.rex"
