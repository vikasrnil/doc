#!/bin/bash

BAUDRATE=921600

PORT=$(ls /dev/ttyUSB* 2>/dev/null | sort -V | tail -n 1)

if [ -z "$PORT" ]
then
    echo "ERROR: No ttyUSB ports found"
    exit 1
fi

echo "Selected highest port: $PORT"

stty -F "$PORT" $BAUDRATE raw -echo

if [ $? -ne 0 ]
then
    echo "ERROR: Failed to configure serial port"
    exit 1
fi

echo "Serial port configured"

exec 3<> "$PORT"

timeout 1 cat <&3 > /dev/null 2>&1

send_cmd()
{
    cmd="$1"

    echo ""
    echo "=========================================="
    echo "Sending: $cmd"
    echo "=========================================="

    # Send command
    echo -ne "$cmd\r\n" >&3

    # Wait for response
    sleep 2

    # Read response
    response=$(timeout 3 cat <&3)

    # Print response
    echo "$response"
}

echo ""
echo "=========================================="
echo "Starting EVB Configuration"
echo "=========================================="

send_cmd "cell --state on"

send_cmd "cell"

send_cmd "gnss --vrslog on"

send_cmd "ntripclient --type SelfBuild"

#Configure NTRIP caster
send_cmd "ntripclient --host 192.168.1.xxx --port 1001 --user admin --pwd 123456 --mnt AUTO"

send_cmd "ntrip --mode rover"

echo ""
echo "=========================================="
echo "EVB setup completed"
echo "=========================================="

cat "$PORT"
