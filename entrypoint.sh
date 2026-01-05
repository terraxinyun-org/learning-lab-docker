#!/bin/bash

# Get current machine ID from Fly.io environment
MACHINE_ID=${FLY_MACHINE_ID:-"unknown"}
echo "Starting lab for machine: $MACHINE_ID"

# Create router script
mkdir -p /tmp/router
cd /tmp/router

cat > package.json << 'EOF'
{"dependencies":{"http-proxy":"^1.18.1"}}
EOF

cat > router.js << 'ROUTEREOF'
const http = require('http');
const httpProxy = require('http-proxy');

const proxy = httpProxy.createProxyServer({
  target: 'http://127.0.0.1:8081',
  ws: true
});

const MACHINE_ID = process.env.FLY_MACHINE_ID || 'unknown';

proxy.on('error', (err, req, res) => {
  console.error('Proxy error:', err);
  if (res.writeHead) {
    res.writeHead(502);
    res.end('Proxy error');
  }
});

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const requestedMachine = url.searchParams.get('machine');

  // If machine param specified and doesn't match, replay to correct one
  if (requestedMachine && requestedMachine !== MACHINE_ID) {
    console.log(`Replaying to machine: ${requestedMachine}`);
    res.setHeader('fly-replay', `instance=${requestedMachine}`);
    res.writeHead(307);
    res.end();
    return;
  }

  proxy.web(req, res);
});

server.on('upgrade', (req, socket, head) => {
  proxy.ws(req, socket, head);
});

server.listen(8080, '0.0.0.0', () => {
  console.log(`Router listening on 0.0.0.0:8080, machine ID: ${MACHINE_ID}`);
});
ROUTEREOF

# Install dependencies
npm install --silent 2>/dev/null

# Start router in background
node router.js &
ROUTER_PID=$!

# Wait a moment for router to start
sleep 2

# Ensure starter folder exists
mkdir -p /home/coder/starter

# Start code-server on port 8081 with home directory (starter is subfolder)
echo "Starting code-server on port 8081..."
exec /usr/bin/code-server --bind-addr 0.0.0.0:8081 --auth password /home/coder
