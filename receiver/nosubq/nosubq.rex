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
ch = .headers~connhdr12

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
if t = "" then dest = "/queue/rexx.receive"
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

-- SUBSCRIBE to the DESTINATION
-- This SUBSCRIBE does not specify a subscription specific message queue.
-- MESSAGE frames will be placed on the system wide message queue.
-- Call "receive" to get messages from this queue (as shown below).
src = sc~subscribe(sunh1)
say "recv12 subscribe rc is" src time("L")


-- Start receives
say "receive demo starts" time("L")
mc = 0
do until mc >= nmsgs

    -- Call receive API
    say "Calling receive:" time("L")
    aframe = sc~receive(0.3)

    -- Handle any response
    select
        when aframe~command == .stc~ERROR then do
            aframe~pp("ERROR Frame from broker:")
            sc~shutdowwn
            exit
        end
        when aframe~command == .stc~RECEIPT then do
            aframe~pp("Unexpected RECEIPT Frame from broker:")
        end
        when aframe~command == .stc~MESSAGE then do
            aframe~pp("Received MESSAGE Frame:")
            mc = mc + 1                         -- Bump message count
        end
    end

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
