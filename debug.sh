#!/bin/bash

# Define the debug port to monitor (can be overridden by environment variable or command line argument)
DEBUG_PORT=${1:-${DEBUG_PORT:-10592}}
DURATION=30

# Convert the port to uppercase hexadecimal format (used in /proc/net/tcp)
HEX_PORT=$(printf "%04X" "$DEBUG_PORT" | awk '{print toupper($0)}')

# Get the current timestamp for logging
NOW=$(date "+%Y-%m-%d %H:%M:%S")

# Function to resolve an IP address to a hostname
get_hostname() {
  local ip="$1"
  local name=""

  # 1. Try reverse DNS lookup using nslookup
  name=$(nslookup "$ip" 2>/dev/null | awk -F': ' '/name =/ {print $2}' | sed 's/\.$//')
  if [[ -n "$name" ]]; then echo "$name"; return; fi

  # 2. Try getent (works with DNS or LDAP)
  name=$(getent hosts "$ip" | awk '{print $2}')
  if [[ -n "$name" ]]; then echo "$name"; return; fi

  # 3. Try ping with hostname resolution
  name=$(ping -c 1 -a "$ip" 2>/dev/null | head -n1 | sed -n 's/^PING \([^ ]\+\).*/\1/p')
  if [[ -n "$name" && "$name" != "$ip" ]]; then echo "$name"; return; fi

  # 4. Fallback if no resolution succeeded
  echo "Unknown"
}

# Function to convert a hex IP address to dotted decimal format
hex2ip() {
  local hex_ip=$1
  # Convert little-endian hex to IP address
  printf "%d.%d.%d.%d\n" \
    $((0x${hex_ip:6:2})) \
    $((0x${hex_ip:4:2})) \
    $((0x${hex_ip:2:2})) \
    $((0x${hex_ip:0:2}))
}

# Log the start of the check
echo "$NOW Checking established TCP connections on port $DEBUG_PORT..."

# Flag to track if any connection is found
found=0

# Read each line from /proc/net/tcp (excluding the header)
while read -r sl local_addr rem_addr st tx_queue rx_queue tr tm_when retrnsmt uid timeout inode; do
  # Skip empty lines
  [[ -z "$sl" ]] && continue
  
  # Extract the local port in hex
  local_port_hex=$(echo "$local_addr" | cut -d':' -f2)

  # Check if the local port matches and the connection is ESTABLISHED (state 01)
  if [[ "$local_port_hex" == "$HEX_PORT" && "$st" == "01" ]]; then
    found=1  # Mark that a connection was found

    echo "Raw connection: $sl $local_addr $rem_addr $st"  # Print the raw connection line for reference

    # Extract and convert remote IP and port
    remote_ip_hex=$(echo "$rem_addr" | cut -d':' -f1)
    remote_ip=$(hex2ip "$remote_ip_hex")
    remote_port_hex=$(echo "$rem_addr" | cut -d':' -f2)
    remote_port=$((16#$remote_port_hex))

    # Resolve the remote hostname
    remote_hostname=$(get_hostname "$remote_ip")

    # Log the connection details
    echo "$NOW Remote connection from host $remote_hostname $remote_ip:$remote_port on debug port $DEBUG_PORT"

    # Use tcpkill to terminate the connection to the remote IP
    echo "$NOW Attempting to kill TCP connection to $remote_ip on port $remote_port using tcpkill..."
    timeout "$DURATION" tcpkill -i any host "$remote_ip" and port "$remote_port" || true
  fi
done < <(tail -n +2 /proc/net/tcp)   # Skip the header line

# Check IPv6 connections as well
while read -r sl local_addr rem_addr st tx_queue rx_queue tr tm_when retrnsmt uid timeout inode; do
  # Skip empty lines
  [[ -z "$sl" ]] && continue
  
  # Extract the local port in hex
  local_port_hex=$(echo "$local_addr" | cut -d':' -f5)  # IPv6 format is different

  # Check if the local port matches and the connection is ESTABLISHED (state 01)
  if [[ "$local_port_hex" == "$HEX_PORT" && "$st" == "01" ]]; then
    found=1  # Mark that a connection was found

    echo "Raw IPv6 connection: $sl $local_addr $rem_addr $st"

    # For IPv6, we'll skip tcpkill as it often doesn't support IPv6
    echo "$NOW IPv6 connection found on debug port $DEBUG_PORT - tcpkill may not support IPv6"
  fi
done < <(tail -n +2 /proc/net/tcp6 2>/dev/null || echo "")

# If no connection was found, log that
if [[ $found -eq 0 ]]; then
  echo "$NOW No established connections found on port $DEBUG_PORT."
fi
