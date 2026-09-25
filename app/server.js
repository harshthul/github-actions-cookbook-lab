'use strict';
// Ch7 sample container app: tiny HTTP server with /healthz and a version endpoint.
const http = require('node:http');

const PORT = Number(process.env.PORT || 8080);
const VERSION = process.env.APP_VERSION || 'dev';

function handler(req, res) {
  if (req.url === '/healthz') {
    res.writeHead(200, { 'content-type': 'text/plain' });
    return res.end('ok');
  }
  if (req.url === '/version') {
    res.writeHead(200, { 'content-type': 'application/json' });
    return res.end(JSON.stringify({ version: VERSION, node: process.versions.node }));
  }
  res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
  res.end(`<h1>GitHub Actions Cookbook lab</h1><p>version ${VERSION}</p>`);
}

const server = http.createServer(handler);
if (require.main === module) {
  server.listen(PORT, () => console.log(`listening on :${PORT} (version ${VERSION})`));
  process.on('SIGTERM', () => server.close(() => process.exit(0)));
}
module.exports = { handler };
