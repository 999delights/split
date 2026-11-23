"""Machine folders and programs this app uses, from configuration.

The table is host-paths.json; hostPaths.cjs reads the same table for Node, PowerShell and the workflows. One base,
TD_ARTIUM_ROOT (D:\\artium on Windows), holds secrets, runtime, share and apps; the other roots sit outside it. Every
root can also be set on its own variable. Outside Windows nothing is guessed: an unset root is an error that names the
variable to set. Same convention as the platform's shared/centralPaths.cjs.
"""
import json
import ntpath
import os
import posixpath
import sys
from pathlib import Path

_TABLE = json.loads(Path(__file__).with_name('host-paths.json').read_text(encoding='utf-8'))
ROOTS = _TABLE['roots']
TOOLS = _TABLE['tools']


def _context(env, platform):
    windows = (platform or sys.platform) == 'win32'
    return (os.environ if env is None else env), windows, (ntpath if windows else posixpath)


def host_root(name, env=None, platform=None):
    """The folder for one root; read on every call, so a variable set later still counts."""
    env, windows, paths = _context(env, platform)
    entry = ROOTS.get(name)
    if entry is None:
        raise ValueError(f'Unknown machine folder: {name}')
    if env.get(entry['variable']):
        return env[entry['variable']]
    if 'under' in entry:
        artium = ROOTS['artium']
        base = env.get(artium['variable']) or (artium['windows'] if windows else '')
        if base:
            return paths.normpath(paths.join(base, entry['under']))
        raise RuntimeError(f"Set {entry['variable']} or {artium['variable']} on this machine: "
                           f'the {name} folder is not known here.')
    if windows:
        return entry['windows']
    raise RuntimeError(f"Set {entry['variable']} on this machine: the {name} folder is not known here.")


def host_path(name, *parts, env=None, platform=None):
    """A path inside one root, joined the way this machine joins paths."""
    _, _, paths = _context(env, platform)
    return paths.normpath(paths.join(host_root(name, env=env, platform=platform), *parts))


def host_tool(name, env=None, platform=None):
    """The program to run: its variable, else today's Windows install, else the command on PATH."""
    env, windows, _ = _context(env, platform)
    entry = TOOLS.get(name)
    if entry is None:
        raise ValueError(f'Unknown program: {name}')
    return env.get(entry['variable']) or (entry['windows'] if windows else entry['command'])
