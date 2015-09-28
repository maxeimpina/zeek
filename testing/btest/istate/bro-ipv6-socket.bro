# @TEST-KNOWN-FAILURE: fails due to auto_publish/auto_advertise flags
# @TEST-SERIALIZE: comm
#
# @TEST-REQUIRES: ifconfig | grep -q -E "inet6 ::1|inet6 addr: ::1"
#
# @TEST-EXEC: btest-bg-run recv bro -b ../recv.bro
# @TEST-EXEC: btest-bg-run send bro -b ../send.bro
# @TEST-EXEC: btest-bg-wait 20
#
# @TEST-EXEC: btest-diff recv/.stdout
# @TEST-EXEC: btest-diff send/.stdout

@TEST-START-FILE send.bro

@load base/frameworks/communication

redef Communication::nodes += {
    ["foo"] = [$host=[::1], $connect=T, $retry=1sec]
};

global my_event: event(s: string);

event bro_init() &priority=5
	{
	BrokerComm::subscribe_to_events("bro/event/");
	}

event BrokerComm::outgoing_connection_established(peer_address: string,
                                             peer_port: port,
                                             peer_name: string)
	{
	print fmt("handshake done with peer: %s", peer_address);
	}

event my_event(s: string)
	{
	print fmt("my_event: %s", s);
	terminate();
	}

@TEST-END-FILE

#############

@TEST-START-FILE recv.bro

@load frameworks/communication/listen

redef exit_only_after_terminate = T;
redef Communication::listen_interface=[::];

global my_event: event(s: string);

event BrokerComm::incoming_connection_established(peer_name: string)
	{
	print fmt("handshake done with peer: %s", peer_name);
	BrokerComm::send_event("bro/event/my_event", BrokerComm::event_args(my_event, "hello world"));
	}

event BrokerComm::incoming_connection_broken(peer_name: string)
	{
	terminate();
	}

@TEST-END-FILE
