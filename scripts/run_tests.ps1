param(
  [ValidateSet("smoke", "regression", "full")]
  [string]$Profile = "smoke",
  [switch]$Expanded,
  [switch]$NoPub,
  [switch]$UseTags,
  [int]$TimeoutSeconds = 480,
  [switch]$KeepGoing,
  [switch]$SkipPreflight,
  [switch]$Clean,
  [switch]$PubGet,
  [switch]$IncludeQuarantine,
  [switch]$ClearFlutterLocks,
  [switch]$NoSuppressAnalytics
)

$ErrorActionPreference = "Stop"
$script:Reporter = if ($Expanded.IsPresent) { "expanded" } else { "compact" }
$script:NoPubResolved = $NoPub.IsPresent
$script:SuppressAnalytics = -not $NoSuppressAnalytics.IsPresent
$script:FlutterExe = "flutter"
$script:Failed = $false

function Write-Step([string]$message) {
  Write-Host "==> $message"
}

function Get-FlutterCacheLockFiles {
  $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
  if (-not $flutterCmd) {
    return @()
  }

  $flutterExePath = $flutterCmd.Source
  $flutterBinDir = Split-Path $flutterExePath -Parent
  $cacheDir = Join-Path $flutterBinDir "cache"
  return @(
    (Join-Path $cacheDir "lockfile"),
    (Join-Path $cacheDir "flutter.bat.lock")
  )
}

function Ensure-PreferredGitOnPath {
  $preferredGitDir = "C:\Program Files\Git\cmd"
  if (-not (Test-Path -LiteralPath $preferredGitDir)) {
    return
  }

  $currentGit = Get-Command git -ErrorAction SilentlyContinue
  if ($currentGit -and $currentGit.Source -like "$preferredGitDir*") {
    return
  }

  $env:PATH = "$preferredGitDir;$env:PATH"
  $resolvedGit = Get-Command git -ErrorAction SilentlyContinue
  if ($resolvedGit) {
    Write-Step "Git preferencial aplicado no PATH: $($resolvedGit.Source)"
  }
}

function Stop-OrphanToolProcesses {
  $processNames = @("flutter", "dart", "flutter_tester", "dartaotruntime")
  $running = Get-Process -ErrorAction SilentlyContinue | Where-Object { $processNames -contains $_.ProcessName }
  if ($null -eq $running -or $running.Count -eq 0) {
    return
  }

  Write-Step "Encerrando processos pendurados: $($running.ProcessName -join ', ')"
  $running | Stop-Process -Force -ErrorAction SilentlyContinue
}

function Remove-IfExists([string]$path, [switch]$Recurse) {
  if (-not (Test-Path -LiteralPath $path)) {
    return
  }

  try {
    if ($Recurse.IsPresent) {
      Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
    }
    else {
      Remove-Item -LiteralPath $path -Force -ErrorAction Stop
    }
  }
  catch {
    Write-Host "Aviso: nao foi possivel remover '$path': $($_.Exception.Message)"
  }
}

function Invoke-FlutterCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments,
    [string]$Label = "flutter command"
  )

  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  & $script:FlutterExe @Arguments 2>&1 | Out-Host
  $exitCode = $LASTEXITCODE
  $sw.Stop()
  return [pscustomobject]@{
    Label        = $Label
    ExitCode     = $exitCode
    TimedOut     = $false
    DurationSec  = [Math]::Round($sw.Elapsed.TotalSeconds, 1)
    ArgumentLine = ($Arguments -join " ")
  }
}

function Invoke-Preflight {
  if ($SkipPreflight.IsPresent) {
    Write-Step "Preflight ignorado por -SkipPreflight."
    return
  }

  Write-Step "Preflight: limpando estado de execucao no Windows."
  Ensure-PreferredGitOnPath
  Stop-OrphanToolProcesses

  if ($ClearFlutterLocks.IsPresent) {
    foreach ($lockfile in (Get-FlutterCacheLockFiles)) {
      Remove-IfExists -path $lockfile
    }
  }
  else {
    Write-Step "Lockfiles do SDK preservados (use -ClearFlutterLocks para limpar)."
  }

  Remove-IfExists -path "build\unit_test_assets" -Recurse
  Remove-IfExists -path "build\native_assets" -Recurse

  if ($Clean.IsPresent) {
    Write-Step "Executando flutter clean..."
    $cleanArgs = @()
    if ($script:SuppressAnalytics) { $cleanArgs += "--suppress-analytics" }
    $cleanArgs += "clean"
    $result = Invoke-FlutterCommand -Arguments $cleanArgs -Label "flutter clean"
    if ($result.ExitCode -ne 0) {
      throw "Falha no flutter clean (EXIT=$($result.ExitCode))."
    }
  }

  if ($PubGet.IsPresent) {
    Write-Step "Executando flutter pub get..."
    $pubGetArgs = @()
    if ($script:SuppressAnalytics) { $pubGetArgs += "--suppress-analytics" }
    $pubGetArgs += @("pub", "get")
    $result = Invoke-FlutterCommand -Arguments $pubGetArgs -Label "flutter pub get"
    if ($result.ExitCode -ne 0) {
      throw "Falha no flutter pub get (EXIT=$($result.ExitCode))."
    }
  }
}

function Resolve-TestFiles([string]$selectedProfile) {
  $smokeStable = @(
    "test/features/goals/domain/focus_streak_calculator_test.dart",
    "test/features/goals/domain/goal_action_domain_test.dart",
    "test/features/goals/domain/goal_daily_completion_calculator_test.dart"
  )

  $regressionCore = @(
    "test/features/onboarding/presentation/onboarding_flow_test.dart",
    "test/features/goals/data/mapper_compatibility_test.dart",
    "test/features/goals/presentation/focus_streak_persistence_test.dart"
  )

  $quarantine = @(
    "test/app/theme/theme_contrast_audit_test.dart"
  )

  $fullOnly = @(
    "test/widgets/home_and_settings_widget_test.dart",
    "test/widgets/focus_widget_test.dart",
    "test/widgets/dashboard_and_goal_detail_widget_test.dart",
    "test/widgets/priorities_and_layout_widget_test.dart",
    "test/widget_test.dart"
  )

  switch ($selectedProfile) {
    "smoke" { $base = $smokeStable }
    "regression" { $base = @($smokeStable + $regressionCore) }
    "full" { $base = @($smokeStable + $regressionCore + $fullOnly) }
  }

  if ($IncludeQuarantine.IsPresent) {
    return @($base + $quarantine)
  }

  return $base
}

function Resolve-Tags([string]$selectedProfile) {
  switch ($selectedProfile) {
    "smoke" { return @("smoke") }
    "regression" { return @("smoke", "regression") }
    "full" { return @("smoke", "regression", "full") }
  }
}

function Build-TestArguments([string]$target, [bool]$isTag) {
  $args = @()
  if ($script:SuppressAnalytics) {
    $args += "--suppress-analytics"
  }

  $args += "test"
  if ($isTag) {
    $args += @("--tags", $target)
  }
  else {
    $args += $target
  }
  $args += @("-r", $script:Reporter, "--concurrency=1")
  if ($TimeoutSeconds -gt 0) {
    $args += @("--timeout", "${TimeoutSeconds}s")
  }
  if ($script:NoPubResolved) {
    $args += "--no-pub"
  }

  return $args
}

function Invoke-TestTarget([string]$target, [bool]$isTag) {
  Write-Host ""
  Write-Host (">>> " + ($(if ($isTag) { "tag" } else { "file" })) + ": $target")

  $label = if ($isTag) { "tag:$target" } else { "file:$target" }
  $args = Build-TestArguments -target $target -isTag $isTag
  $result = Invoke-FlutterCommand -Arguments $args -Label $label

  Write-Host ("EXIT=" + $result.ExitCode + " TIME=" + $result.DurationSec + "s")
  return $result
}

function Print-Summary([array]$results) {
  Write-Host ""
  Write-Host "Resumo de execucao:"
  $validResults = @($results | Where-Object {
    $_ -is [pscustomobject] -and
    ($null -ne $_.Label) -and
    ($null -ne $_.ExitCode) -and
    ($null -ne $_.DurationSec)
  })
  foreach ($r in $validResults) {
    $status = if ($r.ExitCode -eq 0) { "OK" } elseif ($r.TimedOut) { "TIMEOUT" } else { "FAIL" }
    Write-Host ("- " + $r.Label + " | " + $status + " | " + $r.DurationSec + "s | EXIT=" + $r.ExitCode)
  }
}

Invoke-Preflight

$results = @()
if ($UseTags.IsPresent) {
  $targets = Resolve-Tags -selectedProfile $Profile
  if (-not $IncludeQuarantine.IsPresent) {
    Write-Host "Aviso: modo -UseTags ignora quarentena de arquivos. Para pular testes instaveis, rode por arquivos (sem -UseTags)."
  }
  Write-Step "Executando perfil '$Profile' por tags com reporter '$script:Reporter'..."
  foreach ($tag in $targets) {
    $result = Invoke-TestTarget -target $tag -isTag $true
    $results += $result
    if ($result.ExitCode -ne 0) {
      $script:Failed = $true
      if (-not $KeepGoing.IsPresent) { break }
    }
  }
}
else {
  $targets = Resolve-TestFiles -selectedProfile $Profile
  Write-Step "Executando perfil '$Profile' por arquivos com reporter '$script:Reporter'..."
  foreach ($file in $targets) {
    $result = Invoke-TestTarget -target $file -isTag $false
    $results += $result
    if ($result.ExitCode -ne 0) {
      $script:Failed = $true
      if (-not $KeepGoing.IsPresent) { break }
    }
  }
}

Print-Summary -results $results
if ($script:Failed) {
  throw "Execucao finalizada com falhas. Revise o resumo acima."
}

Write-Host ""
Write-Host "Perfil '$Profile' finalizado com sucesso."
