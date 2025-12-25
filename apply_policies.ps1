# apply_policies.ps1

param (
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId
)

# 1. Check Azure Login
Write-Host "Checking Azure connection..." -ForegroundColor Cyan

if (-not [string]::IsNullOrWhiteSpace($SubscriptionId)) {
    Write-Host "Setting subscription context to: $SubscriptionId" -ForegroundColor Cyan
    try {
        az account set --subscription $SubscriptionId
    } catch {
        Write-Error "Failed to set subscription context. Please check the ID and your permissions."
        exit 1
    }
}

try {
    $account = az account show | ConvertFrom-Json
    Write-Host "Connected to: $($account.name) ($($account.id))" -ForegroundColor Green
    
    if ([string]::IsNullOrWhiteSpace($SubscriptionId)) {
        $SubscriptionId = $account.id
        Write-Host "Using Subscription ID from context: $SubscriptionId" -ForegroundColor Gray
    }
} catch {
    Write-Host "Not logged in. Launching browser login..." -ForegroundColor Yellow
    az login
    $account = az account show | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace($SubscriptionId)) {
        $SubscriptionId = $account.id
    }
}

# 2. Deploy Platform Policies (Terraform)
Write-Host "`n--- Deploying Platform Policies ---" -ForegroundColor Cyan

Push-Location "iac/platform/mg-policy"
try {
    if (-not (Get-Command "terraform" -ErrorAction SilentlyContinue)) {
        throw "Terraform is not installed or not in the PATH."
    }

    Write-Host "Initializing Terraform..."
    terraform init -reconfigure
    if ($LASTEXITCODE -ne 0) { throw "Terraform init failed." }
    
    Write-Host "Applying Policies..."
    terraform apply -var="subscription_id=$SubscriptionId" -auto-approve
    if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed." }
    
    Write-Host "Policies applied successfully." -ForegroundColor Green
} catch {
    Write-Error "Terraform deployment failed: $_"
    exit 1
} finally {
    Pop-Location
}
