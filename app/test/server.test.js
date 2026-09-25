'use strict';
const { describe, test } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { handler } = require('../server');

function get(server, path) {
  return new Promise((resolve, reject) => {
    http.get({ port: server.address().port, path }, (res) => {
      let body = '';
      res.on('data', (c) => (body += c));
      res.on('end', () => resolve({ status: res.statusCode, body }));
    }).on('error', reject);
  });
}

describe('cookbook-app', () => {
  test('health, version and home page', async () => {
    const server = http.createServer(handler).listen(0);
    try {
      assert.deepEqual(await get(server, '/healthz'), { status: 200, body: 'ok' });
      const v = await get(server, '/version');
      assert.equal(v.status, 200);
      assert.equal(JSON.parse(v.body).version, 'dev');
      assert.match((await get(server, '/')).body, /Cookbook lab/);
    } finally {
      server.close();
    }
  });
});
