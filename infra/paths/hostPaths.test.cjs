'use strict';
// hostPaths.cjs against the cases test_host_paths.py also runs (cases.json), so both readers agree.
const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { hostPaths } = require('./hostPaths.cjs');
const cases = require('./cases.json');

for (const item of cases) {
  test(item.about, () => {
    const paths = hostPaths({ env: item.env, platform: item.platform });
    const resolve = () => (item.tool ? paths.tool(item.tool) : paths.path(item.root, ...item.parts));
    if (item.error) assert.throws(resolve, error => item.error.every(word => error.message.includes(word)));
    else assert.equal(resolve(), item.expect);
  });
}

const cli = (args, env) => spawnSync(process.execPath, [path.join(__dirname, 'hostPaths.cjs'), ...args], { env, encoding: 'utf8' });

test('the command line prints one path for PowerShell and the workflows', () => {
  const vault = path.resolve('fixture-vault');
  const result = cli(['secrets', 'development', 'split'], { ...process.env, TD_SECRETS_ROOT: vault });
  assert.equal(result.status, 0);
  assert.equal(result.stdout.trim(), path.join(vault, 'development', 'split'));
});

test('the command line fails with the reason, not a guess', () => {
  const result = cli(['nowhere'], process.env);
  assert.equal(result.status, 1);
  assert.equal(result.stdout, '');
  assert.match(result.stderr, /Unknown machine folder: nowhere/);
});
