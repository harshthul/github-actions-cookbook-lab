import test from 'node:test';
import assert from 'node:assert/strict';
import { buildGreeting, parseStyle } from '../src/greeting.js';

test('plain greeting', () => {
  assert.equal(buildGreeting('Octocat'), 'Hello, Octocat!');
});

test('shout and emoji styles', () => {
  assert.equal(buildGreeting('ci', 'shout'), 'HELLO, CI!');
  assert.equal(buildGreeting('ci', 'emoji'), ':wave: Hello, ci!');
});

test('parseStyle validates input', () => {
  assert.equal(parseStyle(' SHOUT '), 'shout');
  assert.equal(parseStyle(undefined), 'plain');
  assert.throws(() => parseStyle('loud'), /style must be one of/);
});

test('empty name is rejected', () => {
  assert.throws(() => buildGreeting('  '), /must not be empty/);
});
