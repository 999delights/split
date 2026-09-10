const path = require('node:path');
const port = Number(process.env.SPLIT_DEV_PORT);
if (!Number.isInteger(port) || port < 1024 || port > 65535) throw new Error('Explicit Split development port required');
if (!process.env.SPLIT_DEV_PYTHON) throw new Error('Split development Python required');
for (const name of ['SMTP_HOST', 'SMTP_PORT', 'SMTP_SECURITY', 'SMTP_USER', 'SMTP_PASSWORD']) {
  if (!process.env[name]) throw new Error(`Missing required environment variable: ${name}`);
}
module.exports = { apps: [{
  name: 'split-server',
  script: process.env.SPLIT_DEV_PYTHON,
  interpreter: 'none',
  args: ['-m', 'services.identity.runtime', '--product', 'split',
    '--env-file', 'D:\\app-runtime\\config\\development\\split.identity.env',
    '--database-file', 'D:\\app-runtime\\config\\development\\split.database.env',
    '--port', String(port)],
  cwd: path.resolve(__dirname, '..', '..'),
  autorestart: true,
  watch: false,
  env: {
    APP_ENV: 'development',
    SMTP_HOST: process.env.SMTP_HOST,
    SMTP_PORT: process.env.SMTP_PORT,
    SMTP_SECURITY: process.env.SMTP_SECURITY,
    SMTP_USER: process.env.SMTP_USER,
    SMTP_PASSWORD: process.env.SMTP_PASSWORD,
  },
}] };
