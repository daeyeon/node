'use strict';
// const common = require('../common');
const assert = require('node:assert');
const { Worker, isMainThread } = require('node:worker_threads');

const symbol = Symbol('sym');

// process.env[symbol] = 42;
// process.env.foo = symbol;


// delete process.env[symbol]

// return;

// assert.strictEqual(delete process.env[symbol], true);

// assert.strictEqual(symbol in process.env, false);

// symbol in process.env;

// return;

function test() {
  const e = {
    code: 'ERR_INVALID_ENV_CHAR',
  };


  // console.log(process.env['SHELL\0TERM']);
  process._rawDebug('/Start');
  //console.log(process.env);
  //Object.entries(process.env);
  // for (const item in process.env)
  {
    ;
  }
  Object.keys(process.env);
  process._rawDebug('/End');
  //process.env.SHELL = 'HELLO\0GOODBYE';


  // console.log('TERM' in process.env);

  //console.log('SHELL\0TERM' in process.env);

  // process.env['SHELL\0TERM'] = 'HELLO';

  // delete process.env['SHELL\0TERM'];
}

if (isMainThread) {
  test();
  // new Worker(__filename);
} else {
  //test();
}
