#!/bin/bash
set -eu

echo '' > /etc/tor/torrc

if [[ $RELAY_TYPE == "bridge" ]]; then
    echo "BridgeRelay 1" >> /etc/tor/torrc
    echo "ServerTransportPlugin obfs4 exec /usr/bin/obfs4proxy" >> /etc/tor/torrc
    echo "ServerTransportListenAddr obfs4 0.0.0.0:$RELAY_BRIDGE_PORT" >> /etc/tor/torrc
fi

echo "ExtORPort auto" >> /etc/tor/torrc
echo "ExitPolicy reject *:*" >> /etc/tor/torrc
echo "ORPort $RELAY_PORT" >> /etc/tor/torrc
echo "Nickname $RELAY_NICKNAME" >> /etc/tor/torrc
echo "ContactInfo $CONTACT_INFO" >> /etc/tor/torrc
echo "RelayBandwidthRate $RELAY_BANDWIDTH_RATE" >> /etc/tor/torrc
echo "RelayBandwidthBurst $RELAY_BANDWIDTH_BURST" >> /etc/tor/torrc
