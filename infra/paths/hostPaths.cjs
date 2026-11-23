'use strict';
// Machine folders and programs this app uses, from configuration. The table is host-paths.json; host_paths.py reads
// the same table for the Python code. One base, TD_ARTIUM_ROOT (D:\artium on Windows), holds secrets, runtime, share
// and apps; the other roots sit outside it. Every root can also be set on its own variable. Outside Windows nothing is
// guessed: an unset root is an error that names the variable to set. Same convention as the platform's
// shared/centralPaths.cjs.
//   node infra/paths/hostPaths.cjs secrets development split   prints that path (PowerShell scripts and workflows)
//   node infra/paths/hostPaths.cjs --tool python               prints the program to run
const path = require('node:path');
const { roots: ROOTS, tools: TOOLS } = require('./host-paths.json');

function hostPaths({ env = process.env, platform = process.platform } = {}) {
  const windows = platform === 'win32';
  const join = windows ? path.win32.join : path.posix.join;
  const root = name => {
    const entry = ROOTS[name];
    if (!entry) throw new Error(`Unknown machine folder: ${name}`);
    if (env[entry.variable]) return env[entry.variable];
    if (entry.under) {
      const base = env[ROOTS.artium.variable] || (windows ? ROOTS.artium.windows : '');
      if (base) return join(base, entry.under);
      throw new Error(`Set ${entry.variable} or ${ROOTS.artium.variable} on this machine: the ${name} folder is not known here.`);
    }
    if (windows) return entry.windows;
    throw new Error(`Set ${entry.variable} on this machine: the ${name} folder is not known here.`);
  };
  const at = (name, ...parts) => join(root(name), ...parts);
  const tool = name => {
    const entry = TOOLS[name];
    if (!entry) throw new Error(`Unknown program: ${name}`);
    return env[entry.variable] || (windows ? entry.windows : entry.command);
  };
  return { root, path: at, tool };
}

// Read on every call, so a variable set after loading still counts.
const hostRoot = name => hostPaths().root(name);
const hostPath = (name, ...parts) => hostPaths().path(name, ...parts);
const hostTool = name => hostPaths().tool(name);

module.exports = { hostPaths, hostRoot, hostPath, hostTool };

if (require.main === module) {
  const [first, ...rest] = process.argv.slice(2);
  try {
    process.stdout.write(`${first === '--tool' ? hostTool(rest[0]) : hostPath(first, ...rest)}\n`);
  } catch (error) {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  }
}
