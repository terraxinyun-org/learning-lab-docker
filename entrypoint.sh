#!/bin/bash

# Ensure starter folder exists
mkdir -p /home/coder/starter

# Start code-server directly on port 8080
echo "Starting code-server..."
exec /usr/bin/code-server --bind-addr 0.0.0.0:8080 --auth password /home/coder
