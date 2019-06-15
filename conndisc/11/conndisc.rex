--
-- Connect to a STOMP broker asking for protocol level 1.1
--
-- Connect parameter 1:  a socket instance
--
socket = .netconn~open(.nil)
--
-- Connect parameter 2:  a connect headers instance
--
ch = .headers~connhdr11
--
-- Connect parameter 3:  a directory instance for additional connect
-- parameters.
--
cod = .directory~new
--
-- Get a STOMP connection
--
sc = .connection~new(socket, ch, cod)
--
-- Display CONNECT results
--
say "CONNECT Results:"
say "connframe command:" sc~connframe~command
say "session:" sc~session
say "server:" sc~server
say "protocol:" sc~protocol
say
sc~disconnect
--

::requires "../../base.rex"
