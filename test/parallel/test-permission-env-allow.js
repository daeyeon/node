// Flags: --experimental-permission --allow-fs-read=* --allow-child-process
'use strict';

require('../common');
const { spawnSync } = require('node:child_process');
const { inspect, debuglog } = require('node:util');
const { throws, strictEqual } = require('node:assert');
const { describe, it } = require('node:test');
const assert = require('assert');
const debug = debuglog('test');

// TODO: NODE_DEBUG_NATIVE=PERMISSION; ./noded --experimental-permission --allow-fs-read=\* --allow-env=ABC,EFG,-HIJ ./test1.js
// Guarantee the initial state
{
  // TODO: throw permission
  // error: Uncaught TypeError: The provided value "env1" is not a valid permission name.
  assert.ok(!process.permission.has('env'));
}

{
  // test/parallel/test-process-env.js
  // should throw error
  // const keys = Object.keys(process.env);
}

function runTest({ flags, code, options }) {
  const { status, stdout, stderr } = spawnSync(
    process.execPath,
    ['--experimental-permission', '--allow-fs-read=*', ...flags, '-e', code],
    options
  );

  // debug('status:', status);
  // debug('stdout:', stdout.toString().split('\n'));
  // if (status) debug('stderr:', stderr.toString().split('\n'));

  return { status, stdout, stderr };
}

// TODO: Support   has('env', '*');      // ? * 와 deny가 있을때?
// 이거 * 가 있는걸 확인하는건가?            <-- 이것도 현재 지원안한다. TODO: Doc에 멘션 한다.
// 아님 전체에 대한 권한이 있음을 확인하는걸까? <-- 이건 현재 지원안한다.

// TODO: Support   has('env', 'NODE_*'); // ?

describe('permission: has "env"', () => {
  const code = `
  const has = (...args) => console.log(process.permission.has(...args));

  has('env', '*');
  has('env', 'A1');
  has('env', 'A1,A2');
  has('env', 'A1,B1');
  has('env', 'B1');
  has('env', 'B1,B2');
  has('env', 'NODE_OPTIONS');
  `;

  it('allow one', () => {
    const { status, stdout } = runTest({
      flags: ['--allow-env=A1'],
      code,
    });

    assert.strictEqual(status, 0);
    assert.deepStrictEqual(stdout.toString().split('\n').slice(0, -1), [
      'false',
      'true',
      'false',
      'false',
      'false',
      'false',
      'false',
    ]);
  });

  it('allow more than one', () => {
    const { status, stdout } = runTest({
      flags: ['--allow-env=A1,A2'],
      code,
    });

    assert.strictEqual(status, 0);
    assert.deepStrictEqual(stdout.toString().split('\n').slice(0, -1), [
      'false',
      'true',
      'true',
      'false',
      'false',
      'false',
      'false',
    ]);
  });

  it('allow more than one using wildcard', () => {
    const { status, stdout } = runTest({
      flags: ['--allow-env=A*'],
      code,
    });

    assert.strictEqual(status, 0);
    assert.deepStrictEqual(stdout.toString().split('\n').slice(0, -1), [
      'false',
      'true',
      'true',
      'false',
      'false',
      'false',
      'false',
    ]);
  });

  it('allow more than one with spaces', () => {
    const { status, stdout } = runTest({
      flags: ['--allow-env=A1,   A2   '],
      code,
    });

    assert.strictEqual(status, 0);
    assert.deepStrictEqual(stdout.toString().split('\n').slice(0, -1), [
      'false',
      'true',
      'true',
      'false',
      'false',
      'false',
      'false',
    ]);
  });

  it('allow all', () => {
    const { status, stdout } = runTest({
      flags: ['--allow-env=*'],
      code,
    });

    assert.strictEqual(status, 0);
    assert.deepStrictEqual(stdout.toString().split('\n').slice(0, -1), [
      'true',
      'true',
      'true',
      'true',
      'true',
      'true',
      'true',
    ]);
  });

  it('deny one', () => {
    const { status, stdout } = runTest({
      flags: ['--allow-env=*,-B1'],
      code,
    });

    assert.strictEqual(status, 0);
    assert.deepStrictEqual(stdout.toString().split('\n').slice(0, -1), [
      'true',
      'true',
      'true',
      'false',
      'false',
      'false',
      'true',
    ]);
  });

  it('deny more than one', () => {
    const { status, stdout } = runTest({
      flags: ['--allow-env=*,-A1,-A2'],
      code,
    });

    assert.strictEqual(status, 0);
    assert.deepStrictEqual(stdout.toString().split('\n').slice(0, -1), [
      'false', // true?
      'false',
      'false',
      'false',
      'true',
      'true',
      'true',
    ]);
  });

  it('deny more than one using wildcard', () => {
    const { status, stdout } = runTest({
      flags: ['--allow-env=*,-A*'],
      code,
    });

    assert.strictEqual(status, 0);
    assert.deepStrictEqual(stdout.toString().split('\n').slice(0, -1), [
      'false', // true?
      'false',
      'false',
      'false',
      'true',
      'true',
      'true',
    ]);
  });

  it('deny all', () => {
    const { status, stdout } = runTest({
      flags: ['--allow-env=-*'],
      code,
    });

    assert.strictEqual(status, 0);
    assert.deepStrictEqual(stdout.toString().split('\n').slice(0, -1), [
      'false',
      'false',
      'false',
      'false',
      'false',
      'false',
      'false',
    ]);
  });
});

// console.log(process.execArgv.join(' '));
// cls; NODE_DEBUG=test ./node --test-name-pattern="permission" --test-name-pattern="deny one" test/parallel/test-permission-env-allow.js
