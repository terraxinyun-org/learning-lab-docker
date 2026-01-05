#!/bin/bash

# Get current machine ID from Fly.io environment
CURRENT_MACHINE_ID=${FLY_MACHINE_ID:-"unknown"}

# Start a simple routing proxy on port 8080
# Code-server will run on port 8081
cat > /tmp/router.js << 'EOF'
const http = require('http');
const httpProxy = require('http-proxy');

const proxy = httpProxy.createProxyServer({ target: 'http://127.0.0.1:8081' });
const MACHINE_ID = process.env.FLY_MACHINE_ID || 'unknown';

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const requestedMachine = url.searchParams.get('machine');

  // If machine param specified and doesn't match this machine, replay to correct one
  if (requestedMachine && requestedMachine !== MACHINE_ID) {
    res.setHeader('fly-replay', `instance=${requestedMachine}`);
    res.writeHead(307);
    res.end();
    return;
  }

  // Otherwise proxy to code-server
  proxy.web(req, res);
});

// Handle WebSocket upgrades (needed for code-server)
server.on('upgrade', (req, socket, head) => {
  proxy.ws(req, socket, head);
});

server.listen(8080, () => {
  console.log(`Router running on port 8080, machine ID: ${MACHINE_ID}`);
});
EOF

# Install http-proxy if not present
cd /tmp && npm install http-proxy 2>/dev/null

# Start the router in background
node /tmp/router.js &

# Start code-server on port 8081
exec /usr/bin/code-server --bind-addr 0.0.0.0:8081 --auth password /home/coder/starter
