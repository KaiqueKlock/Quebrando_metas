param(
  [ValidateSet("smoke", "regression", "full")]
  [string]$Profile = "smoke",
  [switch]$Expanded,
  [switch]$NoPub,
  [switch]$UseTags
)

$ErrorActionPreference = "Stop"

function Invoke-Preflight {
  Write-Host "==> Preflight: encerrando processos flutter/dart pendurados..."
  $ErrorActionPreference = "SilentlyContinue"
  Get-Process | Where-Object { $_.ProcessName -match "flutter|dart" } | Stop-Process -Force

  Write-Host "==> Preflight: limpando lockfiles do Flutter SDK..."
  Remove-Item -Force "C:\dev\Flutter\flutter\bin\cache\lockfile","C:\dev\Flutter\flutter\bin\cache\flutter.bat.lock"

  Write-Host "==> Preflight: limpando artefatos de teste..."
  Remove-Item -Recurse -Force "build\unit_test_assets","build\native_assets"
  $ErrorActionPreference = "Stop"
}

function Resolve-TestFiles([string]$selectedProfile) {
  $smoke = @(
    "test/app/theme/theme_contrast_audit_test.dart",
    "test/features/goals/data/mapper_compatibility_test.dart",
    "test/features/goals/domain/focus_streak_calculator_test.dart",
    "test/features/goals/domain/goal_action_domain_test.dart"
  )

  $regressionOnly = @(
    "test/features/goals/presentation/focus_streak_persistence_test.dart",
    "test/features/onboarding/presentation/onboarding_flow_test.dart"
  )

  $fullOnly = @(
    "test/ui_golden_test.dart",
    "test/widget_test.dart"
  )

  switch ($selectedProfile) {
    "smoke" { return $smoke }
    "regression" { return @($smoke + $regressionOnly) }
    "full" { return @($smoke + $regressionOnly + $fullOnly) }
  }
}

function Resolve-Tags([string]$selectedProfile) {
  switch ($selectedProfile) {
    "smoke" { return @("smoke") }
    "regression" { return @("smoke", "regression") }
    "full" { return @("smoke", "regression", "full") }
  }
}

function Invoke-TestByFile([string]$file, [string]$reporter, [bool]$noPub) {
  Write-Host ""
  Write-Host ">>> file: $file"
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  if ($noPub) {
    & flutter test $file -r $reporter --concurrency=1 --no-pub
  }
  else {
    & flutter test $file -r $reporter --concurrency=1
  }
  $exitCode = $LASTEXITCODE
  $sw.Stop()
  Write-Host ("EXIT=" + $exitCode + " TIME=" + [Math]::Round($sw.Elapsed.TotalSeconds, 1) + "s")
  if ($exitCode -ne 0) {
    Write-Error "Falha ao executar arquivo: $file"
    exit $exitCode
  }
}

function Invoke-TestByTag([string]$tag, [string]$reporter, [bool]$noPub) {
  Write-Host ""
  Write-Host ">>> tag: $tag"
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  if ($noPub) {
    & flutter test -r $reporter --concurrency=1 --tags $tag --no-pub
  }
  else {
    & flutter test -r $reporter --concurrency=1 --tags $tag
  }
  $exitCode = $LASTEXITCODE
  $sw.Stop()
  Write-Host ("EXIT=" + $exitCode + " TIME=" + [Math]::Round($sw.Elapsed.TotalSeconds, 1) + "s")
  if ($exitCode -ne 0) {
    Write-Error "Falha ao executar tag: $tag"
    exit $exitCode
  }
}

Invoke-Preflight

$reporter = if ($Expanded.IsPresent) { "expanded" } else { "compact" }
$noPub = $NoPub.IsPresent

if ($UseTags.IsPresent) {
  $tags = Resolve-Tags -selectedProfile $Profile
  Write-Host "==> Executando perfil '$Profile' por tags com reporter '$reporter'..."
  foreach ($tag in $tags) {
    Invoke-TestByTag -tag $tag -reporter $reporter -noPub $noPub
  }
}
else {
  $files = Resolve-TestFiles -selectedProfile $Profile
  Write-Host "==> Executando perfil '$Profile' por arquivos com reporter '$reporter'..."
  foreach ($file in $files) {
    Invoke-TestByFile -file $file -reporter $reporter -noPub $noPub
  }
}

Write-Host ""
Write-Host "Perfil '$Profile' finalizado com sucesso."
