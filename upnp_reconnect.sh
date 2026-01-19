#!/usr/bin/env bash

CONTROL_URL="http://192.168.178.1:49000/igdupnp/control/WANIPConn1"
SERVICE_TYPE="urn:schemas-upnp-org:service:WANIPConnection:1"

echo "Current public IPv4:"
OLD_IP=$(curl -4 -s ifconfig.me)
echo "$OLD_IP"
echo ""

echo "Disconnecting router..."

curl -s -X POST "$CONTROL_URL" \
  -H "Content-Type: text/xml; charset=utf-8" \
  -H "SOAPAction: \"${SERVICE_TYPE}#ForceTermination\"" \
  -d "<?xml version=\"1.0\"?>
<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">
<s:Body>
<u:ForceTermination xmlns:u=\"${SERVICE_TYPE}\">
</u:ForceTermination>
</s:Body>
</s:Envelope>" > /dev/null

if [ $? -eq 0 ]; then
    echo "Disconnect command sent successfully"
    echo "Waiting 5 seconds..."
    sleep 5
    
    echo "Requesting connection..."
    
    curl -s -X POST "$CONTROL_URL" \
      -H "Content-Type: text/xml; charset=utf-8" \
      -H "SOAPAction: \"${SERVICE_TYPE}#RequestConnection\"" \
      -d "<?xml version=\"1.0\"?>
<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">
<s:Body>
<u:RequestConnection xmlns:u=\"${SERVICE_TYPE}\">
</u:RequestConnection>
</s:Body>
</s:Envelope>" > /dev/null
    
    echo "Connection request sent"
    echo "Waiting for new IP..."
    sleep 3
    echo ""
    
    echo "New public IPv4:"
    NEW_IP=$(curl -4 -s ifconfig.me)
    echo "$NEW_IP"
    echo ""
    
    if [ "$OLD_IP" != "$NEW_IP" ]; then
        echo "✓ IP changed successfully: $OLD_IP → $NEW_IP"
    else
        echo "⚠ IP did not change (still $OLD_IP)"
    fi
else
    echo "Error: Failed to send disconnect command"
    exit 1
fi
