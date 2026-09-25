#!/usr/bin/env node
'use strict';
const { greet, runtime } = require('./index');

const args = process.argv.slice(2);
const shout = args.includes('--shout');
const name = args.find((a) => !a.startsWith('--'));
console.log(greet(name, { shout }));
if (args.includes('--runtime')) console.log(JSON.stringify(runtime()));
