'use strict';

require('../common');
const assert = require('node:assert');
const { Worker, isMainThread } = require('node:worker_threads');

function test() {
  const e = {
    code: 'ERR_INVALID_ENV_STRING',
  };

  assert.throws(() => {
    console.log(process.env['SHELL\0TERM']);
  }, e);

  assert.throws(() => {
    process.env.SHELL = 'HELLO\0GOODBYE';
  }, e);

  assert.throws(() => {
    process.env['SHELL\0TERM'] = 'HELLO';
  }, e);

  assert.throws(() => {
    console.log('SHELL\0TERM' in process.env);
  }, e);

  assert.throws(() => {
    delete process.env['SHELL\0TERM'];
  }, e);
}

if (isMainThread) {
  test();
  new Worker(__filename);
} else {
  test();
}
