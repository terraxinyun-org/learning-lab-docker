#!/bin/bash

MACHINE_ID=${FLY_MACHINE_ID:-"unknown"}
echo "Starting lab for machine: $MACHINE_ID"

# Ensure starter folder exists
mkdir -p /home/coder/starter

# Start code-server on port 8081 in background
/usr/bin/code-server --bind-addr 0.0.0.0:8081 --auth password /home/coder &
CODE_SERVER_PID=$!

# Wait for code-server to be ready
echo "Waiting for code-server to start..."
while ! curl -s http://127.0.0.1:8081 > /dev/null 2>&1; do
  sleep 1
done
echo "Code-server is ready!"

# Create router for fly-replay
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
  console.error('Proxy error:', err.message);
  if (res && res.writeHead) {
    res.writeHead(502);
    res.end('Proxy error - retrying...');
  }
});

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const requestedMachine = url.searchParams.get('machine');

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
  console.log(`Router on port 8080, machine: ${MACHINE_ID}`);
});
ROUTEREOF

npm install --silent 2>/dev/null
node router.js &

# Keep the script running
wait $CODE_SERVER_PID
