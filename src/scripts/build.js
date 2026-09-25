'use strict';
// "Build" for a plain JS package: syntax-check and write build-info.json that the
// release recipe attaches to the GitHub release.
const fs = require('node:fs');
const { execFileSync } = require('node:child_process');
for (const f of ['lib/index.js', 'lib/cli.js']) execFileSync(process.execPath, ['--check', f], { stdio: 'inherit' });
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
const info = {
  name: pkg.name,
  version: pkg.version,
  commit: process.env.GITHUB_SHA || 'local',
  run: process.env.GITHUB_RUN_ID || 'local',
  node: process.versions.node,
  builtAt: new Date().toISOString(),
};
fs.mkdirSync('dist', { recursive: true });
fs.writeFileSync('dist/build-info.json', JSON.stringify(info, null, 2) + '\n');
console.log(`built ${info.name}@${info.version}`);
