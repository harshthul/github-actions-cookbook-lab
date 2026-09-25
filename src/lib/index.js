'use strict';

/**
 * Returns a greeting. Used by the lab's CI, matrix, release and SBOM recipes.
 * @param {string} [name]
 * @param {{ shout?: boolean }} [options]
 */
function greet(name = 'World', options = {}) {
  if (typeof name !== 'string' || name.trim() === '') {
    throw new TypeError('name must be a non-empty string');
  }
  const text = `Hello, ${name.trim()}!`;
  return options.shout ? text.toUpperCase() : text;
}

/** Semantic version of the running Node.js, handy in matrix logs. */
function runtime() {
  return { node: process.versions.node, platform: process.platform, arch: process.arch };
}

module.exports = { greet, runtime };
