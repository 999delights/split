param(
    [ValidateRange(1024,65535)][int]$Port = 3400,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{40}$')][string]$ExpectedCommit,
    [string]$DeployRoot = 'D:\network_share\apps\development\split',
    [switch]$ApplyMigrations,
    [switch]$BindRecoveredMembers
)
$ErrorActionPreference = 'Stop'
function Invoke-Checked {
    param([string]$FilePath, [string[]]$Arguments)
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Command failed with exit code $LASTEXITCODE" }
}
$repoRoot = (Resolve-Path -LiteralPath $DeployRoot).Path
if ((git -C $repoRoot remote get-url origin).Trim() -notmatch 'github.com[:/]999delights/split(?:\.git)?$') { throw 'Runtime checkout is not 999delights/split; preserve the legacy checkout and prepare the correct clone' }
if ((git -C $repoRoot branch --show-current).Trim() -ne 'dev') { throw 'Split checkout must be on dev' }
if (git -C $repoRoot status --porcelain) { throw 'Split checkout has local changes' }
Invoke-Checked 'git' @('-C', $repoRoot, 'pull', '--ff-only', 'origin', 'dev')
if ((git -C $repoRoot rev-parse HEAD).Trim() -ne $ExpectedCommit) { throw 'Checkout differs from the tested commit' }
$database = 'D:\app-runtime\config\development\split.database.env'
$identity = 'D:\app-runtime\config\development\split.identity.env'
if (-not (Test-Path $database) -or -not (Test-Path $identity)) { throw 'Split development configuration missing' }
. 'D:\app-runtime\tools\import_smtp_env.ps1' -Environment development
$python = 'D:\app-runtime\venvs\development\split\Scripts\python.exe'
if (-not (Test-Path $python)) {
    Invoke-Checked 'python' @('-m', 'venv', 'D:\app-runtime\venvs\development\split')
}
Push-Location $repoRoot
try {
    Invoke-Checked $python @('-m', 'pip', 'install', '-r', 'services\identity\requirements.txt', '-r', 'infra\db\requirements.txt')
    # Configuration-only validation precedes any database mutation.
    Invoke-Checked $python @('-m', 'services.identity.deployment_check', '--env-file', $identity, '--database-file', $database)
    Invoke-Checked $python @('-m', 'unittest', 'services.identity.test_identity', 'services.identity.test_http', 'services.identity.test_provider', 'services.identity.test_provision', 'services.backend.test_mysql_app', '-q')
    Invoke-Checked $python @('infra\db\db.py', 'db:status', '--env-file', $database)
    if ($BindRecoveredMembers -and -not $ApplyMigrations) { throw 'Binding repair requires backup/migration mode' }
    if ($ApplyMigrations) {
        Invoke-Checked $python @('D:\app-runtime\tools\backup_app_database.py', '--environment', 'development', '--app', 'split')
        Invoke-Checked $python @('infra\db\db.py', 'db:migrate', '--env-file', $database)
    }
    if ($BindRecoveredMembers) {
        $source = 'D:\network_share\apps\data-transfer\split-development-legacy-49cff069\imported.db'
        $hash = '49cff069aeaa7ae2850a47f6da8678c0289a78f56d82a04e80c6a4705a9e4ac4'
        Invoke-Checked $python @('scripts\bind_recovered_members.py', '--source', $source, '--sha256', $hash, '--database-file', $database)
        Invoke-Checked $python @('scripts\bind_recovered_members.py', '--source', $source, '--sha256', $hash, '--database-file', $database, '--apply')
    }
    # Pending migrations stop deployment unless explicitly applied above.
    Invoke-Checked $python @('infra\db\db.py', 'db:validate', '--env-file', $database)
    Invoke-Checked $python @('-m', 'services.identity.runtime', '--product', 'split', '--env-file', $identity, '--database-file', $database, '--port', "$Port", '--check')
    # Refuse to take a port belonging to another service.
    $listeners = @(Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue)
    if ($listeners.Count) {
        $splitPid = (pm2.cmd pid split-server | Out-String).Trim()
        if ($splitPid -notmatch '^\d+$' -or @($listeners | Where-Object { $_.OwningProcess -ne [int]$splitPid }).Count) { throw 'Split DEV port is occupied by another process' }
    }
    $env:SPLIT_RELEASE_COMMIT = $ExpectedCommit
    $env:SPLIT_DEV_PORT = "$Port"
    $env:SPLIT_DEV_PYTHON = $python
    Invoke-Checked 'pm2.cmd' @('startOrRestart', 'infra\pm2\ecosystem.config.js', '--only', 'split-server', '--update-env')
    $healthy = $false
    for ($attempt = 0; $attempt -lt 10; $attempt++) {
        Start-Sleep -Seconds 2
        try {
            $health = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/health" -TimeoutSec 3
            if ($health.status -eq 'ok' -and $health.mode -eq 'mysql-identity' -and $health.commit -eq $ExpectedCommit) { $healthy = $true; break }
        } catch { }
    }
    if (-not $healthy) { throw 'Split health check failed; deployment not confirmed' }
    Invoke-Checked 'pm2.cmd' @('save')
    Invoke-Checked $python @('infra\db\db.py', 'db:status', '--env-file', $database)
    Write-Host "Split development deployed: $ExpectedCommit"
} finally {
    Remove-Item Env:SPLIT_DEV_PORT, Env:SPLIT_DEV_PYTHON -ErrorAction SilentlyContinue
    Pop-Location
}
