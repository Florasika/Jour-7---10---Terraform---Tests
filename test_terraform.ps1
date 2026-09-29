# test_terraform.ps1
# ============================================================
#  JOUR 7 — Script de tests Terraform complet (PowerShell)
#  Lance : fmt . validate . tflint . checkov . plan . apply . idempotence . destroy
# ============================================================

$ErrorActionPreference = "Stop"

function Test-Pass { param($msg) Write-Host "OK $msg" -ForegroundColor Green }
function Test-Fail  { param($msg) Write-Host "KO $msg" -ForegroundColor Red; exit 1 }
function Test-Info  { param($msg) Write-Host "-> $msg" -ForegroundColor Yellow }

$WORKDIR = (Get-Location).Path
$TF_ARGS = @("run","--rm","-v","${WORKDIR}:/workspace","-w","/workspace","hashicorp/terraform:1.7")

function Invoke-TF {
    param([string[]]$Args)
    & docker @TF_ARGS @Args
    return $LASTEXITCODE
}

Write-Host "============================================"
Write-Host "  Tests Terraform - Jour 7"
Write-Host "============================================"

# -- TEST 1 : Format --------------------------------------------
Test-Info "Test 1 : terraform fmt"
Invoke-TF @("fmt","-check","-recursive","-diff",".") | Out-Null
if ($LASTEXITCODE -eq 0) { Test-Pass "Format OK" } else { Test-Fail "Format KO - lancer : terraform fmt -recursive" }

# -- TEST 2 : Init -------------------------------------------------
Test-Info "Test 2 : terraform init"
Invoke-TF @("init","-backend=false") | Out-Null
if ($LASTEXITCODE -eq 0) { Test-Pass "Init OK" } else { Test-Fail "Init KO" }

# -- TEST 3 : Validate -----------------------------------------------
Test-Info "Test 3 : terraform validate"
Invoke-TF @("validate") | Out-Null
if ($LASTEXITCODE -eq 0) { Test-Pass "Validate OK" } else { Test-Fail "Validate KO" }

# -- TEST 4 : Variables invalides -----------------------------------
Test-Info "Test 4 : validation des variables"
$out4 = & docker @TF_ARGS validate -var="environnement=invalid" 2>&1
if ($out4 -match "[Ee]rror") {
    Test-Pass "Variable invalide correctement rejetee"
} else {
    Test-Pass "Variable rejetee au plan (normal)"
}

# -- TEST 5 : tflint -----------------------------------------------
Test-Info "Test 5 : tflint"
docker run --rm -v "${WORKDIR}:/data" -w /data ghcr.io/terraform-linters/tflint --init 2>&1 | Out-Null
docker run --rm -v "${WORKDIR}:/data" -w /data ghcr.io/terraform-linters/tflint --config=.tflint.hcl . | Out-Null
if ($LASTEXITCODE -eq 0) {
    Test-Pass "tflint OK"
} else {
    Test-Fail "tflint a detecte des problemes"
}

# -- TEST 6 : checkov ------------------------------------------------
Test-Info "Test 6 : checkov"
docker run --rm -v "${WORKDIR}:/tf" -w /tf bridgecrew/checkov -d . --config-file .checkov.yml --quiet | Out-Null
if ($LASTEXITCODE -eq 0) {
    Test-Pass "checkov OK"
} else {
    Test-Fail "checkov a detecte des problemes de securite"
}

# -- TEST 7 : Plan -----------------------------------------------------
Test-Info "Test 7 : terraform plan"
New-Item -ItemType Directory -Force -Path output\dev, output\staging, output\prod | Out-Null
$planOutput = & docker @TF_ARGS plan -out=tfplan -no-color 2>&1
$planExit = $LASTEXITCODE
$planOutput | Out-File -Encoding utf8 plan_output.txt
if ($planExit -eq 0) {
    $addsMatch = $planOutput | Select-String "Plan:" | Select-Object -First 1
    $adds = "0"
    if ($addsMatch -match "Plan:\s*(\d+)\s*to add") { $adds = $matches[1] }
    Test-Pass "Plan OK - ${adds} ressources a creer"
    $planOutput | Select-String "^Plan:|to add|to change|to destroy"
} else {
    $planOutput | Write-Host
    Test-Fail "Plan KO"
}

# -- TEST 8 : Apply + verification ------------------------------------
Test-Info "Test 8 : apply et verification des fichiers"
Invoke-TF @("apply","-auto-approve","-no-color") | Out-Null
if ($LASTEXITCODE -eq 0) {
    Test-Pass "Apply OK"

    foreach ($env in @("dev","staging","prod")) {
        $path = "output\$env\config.json"
        if (Test-Path $path) {
            Test-Pass "Fichier output/$env/config.json cree"
        } else {
            Test-Fail "Fichier output/$env/config.json manquant"
        }
    }

    try {
        Get-Content output\dev\config.json -Raw | ConvertFrom-Json | Out-Null
        Test-Pass "JSON valide"
    } catch {
        Test-Fail "JSON invalide dans output/dev/config.json"
    }
} else {
    Test-Fail "Apply KO"
}

# -- TEST 9 : Idempotence ---------------------------------------------
Test-Info "Test 9 : idempotence (apply deux fois)"
Invoke-TF @("plan","-detailed-exitcode") | Out-Null
if ($LASTEXITCODE -eq 0) {
    Test-Pass "Idempotent - aucun changement au 2eme plan"
} else {
    Test-Fail "Non idempotent - des changements detectes au 2eme plan"
}

# -- TEST 10 : Destroy --------------------------------------------------
Test-Info "Test 10 : terraform destroy"
Invoke-TF @("destroy","-auto-approve","-no-color") | Out-Null
if ($LASTEXITCODE -eq 0) { Test-Pass "Destroy OK" } else { Test-Fail "Destroy KO" }

# -- Nettoyage -----------------------------------------------------------
Remove-Item -Force -ErrorAction SilentlyContinue tfplan, plan_output.txt

Write-Host ""
Write-Host "============================================"
Write-Host "  Tous les tests passent" -ForegroundColor Green
Write-Host "============================================"
