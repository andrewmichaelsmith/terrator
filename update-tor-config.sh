
#!/bin/bash
# Appends MyFamily based up on CONTACT_INFO on onionoo.org and /root/known_ips
set -eu

# XXX Trusts onionoo to not do anything really nasty
curl -G https://onionoo.torproject.org/details --data-urlencode "contact=$CONTACT_INFO" | jq -r '.relays[] | [.or_addresses, .fingerprint] | flatten | @tsv' > /root/relays

# Remove all current MyFamily
sed -i '/MyFamily/d' /etc/tor/torrc 

for fingerprint in `grep -f /root/known_ips /root/relays | awk '{print $NF}'`; do
    echo "MyFamily $fingerprint" >> /etc/tor/torrc
done;

systemctl reload tor