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

say time("L") "hi"

app = .asycli~new

-- app~sender

app~waitdone
app~disconnect

say;say time("L") "bye"
exit
--
::class asycli public

::method init public
    expose sc sh dest nmsgs rpart subh sdq rdq

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
    sc = .stomprxconn~new(asock, ch, cod)

    -- Check for a good CONNECT
    if sc~connframe~command <> .stc~CONNECTED then do
        sc~connframe~pp("CONNECT Error:")
        exit
    end
    --
    say time("L") "Protocol Level:" sc~protocol
    --
    t = value("STOMP_NMSGS", "", .stc~env)
    nmsgs = 1
    if t <> "" then nmsgs = t
    t = value("STOMP_DEST", "", .stc~env)
    if t = "" then dest = "/queue/rexx.send.receive"
    else dest = t
    say time("L") "NMSGS:" nmsgs
    say time("L") "DEST:" dest

    -- Pattern send headers
    sh = .headers~new
    t = .header~new(.stc~HK_DESTINATION, dest)
    sh~add(t)
    t = .header~new(.stc~HK_CONTENT_TYPE, "text/plain; charset=UTF-8")
    sh~add(t)
    -- sh~pp("Send Headers App:")

    -- To make messages somewhat variable
    rpart = "12345678901234567890"

    -- subscribe headers
    subh = .headers~new
    desth = .header~new(.stc~HK_DESTINATION, dest)
    subh~add(desth)
    id = "asysr_subid"
    idh = .header~new(.stc~HK_ID, id)
    subh~add(idh)

    -- Done queues
    sdq = .queue~new
    rdq = .queue~new

    -- Start async sender and receiver
    self~start("sender")
    self~start("receiver")

-- ::method sender public

::method sender public unguarded
    expose sc sh dest nmsgs rpart sdq
    -- Start SENDs
    say time("L") "send starts"
    mc = 0
    startmsg = 1
    do i = startmsg to nmsgs
        mc = mc + 1                         -- Bump message count
        rp = rpart~substr(1, random(1,20))  -- Random part of the message

        -- Create a message
        om = "Message" i rp
        say time("L") "send test message->" "Count:" i "Length:" om~length "Message:" om

        --  Build send headers
        useh = sh~clone
        t = .header~new(.stc~HK_CONTENT_LENGTH, om~length)
        useh~add(t)    
        t = .header~new("srx_mid", mc) -- A user header
        useh~add(t) 
        t = .header~new("K:A", "V:A")
        useh~add(t)
        t = .header~new("K\B", "V\B")
        useh~add(t)
        t = .header~new("K\C:C", "V:C\C")
        useh~add(t)

        -- Call SEND API
        rc = sc~send(useh, om)
        if rc < 0 then do
            say time("L") "send failed:" rc
            exit
        end

        -- Check if broker sent an ERROR frame
        ef = sc~recverr
        if ef <> .nil then do
            t = time("L") "ERROR frame received from broker:"
            ef~pp(t)
            sc~disconnect
            exit
        end
        -- Let other routines have a slice .....
        if mc // 5 == 0 then call SysSleep 0.025
        
    end
    t = sdq~append(.true)
    say time("L") "send ends"

::method receiver public unguarded
    expose sc nmsgs subh rdq

    say time("L") "receive starts"
    -- Subscription specific queue
    subq = .queue~new
    src = sc~subscribe(subh, subq)
    say  time("L") "recv12 subscribe rc is" src


    -- Start receives
    say  time("L") "receive demo starts"
    mc = 0
    lc = 0
    do until mc >= nmsgs
        lc = lc + 1
        say time("L") "Start next receive loop" lc
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
        t = time("L") "MESSAGE From Broker:"
        aframe~pp(t)
        mc = mc + 1
        --
    end
    src = sc~unsubscribe(subh)
    say  time("L") "recv12 unsubscribe rc is" src
    t = rdq~append(.true)
    say time("L") "receive ends"

::method disconnect public
    expose sc
    -- DISCONNECT and exit
    dh = .headers~new
    rc = .header~new(.stc~HK_RECEIPT, "send.receipt.id")
    dh~add(rc)
    sc~disconnect(dh)
    rf = sc~recvrcpt(0.3)
    say  time("L") "disconnect complete"
    rf~pp("RECEIPT Frame:")

::method waitdone public
    expose sdq rdq
    say time("L") "starting waitdone"
    sdf = .false
    rdf = .false
    do forever
        if \sdf then do
            t = sdq~pull
            if t <> .nil then do
                sdf = .true
                iterate
            end
        end
        if \rdf then do
            t = rdq~pull
            if t <> .nil then do
                rdf = .true
                iterate
            end
        end
        --
        if sdf & rdf then leave
        call SysSleep 0.3
    end
    say time("L") "ending waitdone"

--
::requires "../base.rex"
