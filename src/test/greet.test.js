'use strict';
const { describe, test } = require('node:test');
const assert = require('node:assert/strict');
const { greet, runtime } = require('../lib/index');

// describe() makes the junit reporter emit a <testsuite> (needed by the Ch6 test report)
describe('cookbook-greeter', () => {
  test('greets the world by default', () => {
    assert.equal(greet(), 'Hello, World!');
  });

  test('greets by name and trims', () => {
    assert.equal(greet('  Octocat '), 'Hello, Octocat!');
  });

  test('shouts when asked', () => {
    assert.equal(greet('ci', { shout: true }), 'HELLO, CI!');
  });

  test('rejects empty names', () => {
    assert.throws(() => greet('   '), TypeError);
  });

  test('reports the runtime', () => {
    const r = runtime();
    assert.match(r.node, /^\d+\.\d+\.\d+$/);
    assert.ok(r.platform && r.arch);
  });
});
