# deploy_governance.ps1

param (
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory=$false)]
    [string]$ManagementGroupId,

    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-ai-foundry-prod",

    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "my-genai-app03",

    [Parameter(Mandatory=$false)]
    [switch]$FastDeploy
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



# 3. Phase 1: Platform Policies (Terraform)
Write-Host "`n--- Phase 1: Deploying Platform Policies ---" -ForegroundColor Cyan

if ($FastDeploy) {
    Write-Host "FastDeploy enabled: Skipping Policy Deployment." -ForegroundColor Yellow
} else {
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
    } catch {
        Write-Error "Terraform deployment failed: $_"
        exit 1
    } finally {
        Pop-Location
    }
}



# 5. Phase 3: Infrastructure Setup (Resource Group)
Write-Host "`n--- Phase 3: Setting up Infrastructure ---" -ForegroundColor Cyan
try {
    if ($FastDeploy) {
        Write-Host "FastDeploy enabled: Skipping Resource Group check/creation." -ForegroundColor Yellow
    } else {
        Write-Host "Creating/Updating Resource Group: $ResourceGroupName in $Location..."
        az group create --name $ResourceGroupName --location $Location --tags "Environment=Prod" "Tier=Platform" "ManagedBy=FoundryGovernance"
        if ($LASTEXITCODE -ne 0) { throw "Failed to create Resource Group." }
        Write-Host "Resource Group ready." -ForegroundColor Green
    }
} catch {
    Write-Error "Infrastructure setup failed: $_"
    exit 1
}

# 6. Phase 4: Deploy Foundry Hub & Project
Write-Host "`n--- Phase 4: Deploying Foundry Hub & Project ---" -ForegroundColor Cyan

if (-not [string]::IsNullOrWhiteSpace($ProjectName)) {
    Write-Host "Deploying Project: $ProjectName" -ForegroundColor Cyan

    # Set Environment Variable for Terraform Auth
    $env:ARM_SUBSCRIPTION_ID = $SubscriptionId
    $env:ARM_TENANT_ID = $account.tenantId

    # Define Common Tags
    $CommonTags = @{
        Environment = "Prod"
        AppId = "App-001"
        Tier = "Gold"
        DataClassification = "Confidential"
        "DR-Approved" = "Yes"
    }

    # A. Deploy Hub Dependencies
    Write-Host "`n[Step A] Deploying Shared Hub Resources (Storage, KV, ACR)..." -ForegroundColor Cyan
    Push-Location "iac/foundry/templates/foundry-hub"
    try {
        # Generate tfvars file to handle complex types cleanly
        $HubTags = $CommonTags.Clone()
        $HubTags["CostCenter"] = "CC-Platform-Shared"

        $HubVars = @{
            resource_group_name = $ResourceGroupName
            location = $Location
            hub_name = "${ProjectName}-hub"
            tags = $HubTags
        }
        $HubVars | ConvertTo-Json -Depth 10 | Set-Content "terraform.tfvars.json"

        $tfArgs = @("apply", "-auto-approve")
        if ($FastDeploy) {
            Write-Host "FastDeploy enabled: Skipping refresh and increasing parallelism..." -ForegroundColor Yellow
            $tfArgs += "-refresh=false"
            $tfArgs += "-parallelism=50"
        }

        terraform init -upgrade
        terraform @tfArgs
        if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed" }
        
        # Capture Outputs
        $hubOutputs = terraform output -json | ConvertFrom-Json
        $storageId = $hubOutputs.storage_account_id.value
        $kvId = $hubOutputs.key_vault_id.value
        $aiId = $hubOutputs.application_insights_id.value
        $lawId = $hubOutputs.log_analytics_workspace_id.value
        $acrId = $hubOutputs.container_registry_id.value
        $hubId = $hubOutputs.hub_id.value
        $apimName = $hubOutputs.apim_name.value
        $openaiEndpoint = $hubOutputs.openai_endpoint.value
        $openaiId = $hubOutputs.openai_id.value
        $computeSubnetId = $hubOutputs.compute_subnet_id.value
        $peSubnetId = $hubOutputs.private_endpoints_subnet_id.value
        $searchDnsZoneId = $hubOutputs.search_dns_zone_id.value
        
        Write-Host "Hub Resources Deployed." -ForegroundColor Green
    } catch {
        Write-Error "Hub deployment failed: $_"
        exit 1
    } finally {
        Pop-Location
    }

    # A.1 Deploy Model Router
    Write-Host "`n[Step A.1] Deploying Model Router..." -ForegroundColor Cyan
    Push-Location "iac/foundry/templates/model-router"
    try {
        $RouterVars = @{
            resource_group_name = $ResourceGroupName
            apim_name = $apimName
            openai_endpoint = $openaiEndpoint
        }
        $RouterVars | ConvertTo-Json -Depth 10 | Set-Content "terraform.tfvars.json"

        terraform init -upgrade
        terraform apply -auto-approve
        if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed" }
        Write-Host "Model Router Deployed." -ForegroundColor Green
    } catch {
        Write-Error "Model Router deployment failed: $_"
        exit 1
    } finally {
        Pop-Location
    }

    # B. Deploy Project Template
    Write-Host "`n[Step B] Deploying Foundry Project: $ProjectName..." -ForegroundColor Cyan
    Push-Location "iac/foundry/templates/project-genai-rag"
    try {
        # Generate tfvars file
        $ProjectTags = $CommonTags.Clone()
        $ProjectTags["CostCenter"] = "CC-Project-001"

        $ProjectVars = @{
            project_name = $ProjectName
            resource_group_name = $ResourceGroupName
            location = $Location
            log_analytics_workspace_id = $lawId
            application_insights_id = $aiId
            key_vault_id = $kvId
            storage_account_id = $storageId
            container_registry_id = $acrId
            hub_id = $hubId
            private_endpoints_subnet_id = $peSubnetId
            search_dns_zone_id = $searchDnsZoneId
            cost_center = "CC-Project-001"
            tags = $ProjectTags
        }
        $ProjectVars | ConvertTo-Json -Depth 10 | Set-Content "terraform.tfvars.json"

        terraform init -upgrade
        terraform apply -auto-approve
        if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed" }
            
        Write-Host "Foundry Project Deployed Successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Project deployment failed: $_"
        exit 1
    } finally {
        Pop-Location
    }

    # C. Deploy Agent Tools Project
    Write-Host "`n[Step C] Deploying Agent Tools Project..." -ForegroundColor Cyan
    Push-Location "iac/foundry/templates/project-agent-tools"
    try {
        $AgentTags = $CommonTags.Clone()
        $AgentTags["CostCenter"] = "CC-Agent-Tools"

        $AgentVars = @{
            project_name = "${ProjectName}-agents"
            resource_group_name = $ResourceGroupName
            location = $Location
            application_insights_id = $aiId
            key_vault_id = $kvId
            storage_account_id = $storageId
            container_registry_id = $acrId
            hub_id = $hubId
            subnet_id = $computeSubnetId
            tags = $AgentTags
        }
        $AgentVars | ConvertTo-Json -Depth 10 | Set-Content "terraform.tfvars.json"

        terraform init -upgrade
        terraform apply -auto-approve
        if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed" }
        Write-Host "Agent Tools Project Deployed." -ForegroundColor Green
    } catch {
        Write-Error "Agent Tools deployment failed: $_"
        exit 1
    } finally {
        Pop-Location
    }

    # D. Deploy Monitoring & Cost
    Write-Host "`n[Step D] Deploying Monitoring & Cost..." -ForegroundColor Cyan
    Push-Location "iac/platform/monitoring"
    try {
        $MonitoringTags = $CommonTags.Clone()
        $MonitoringTags["CostCenter"] = "CC-Platform-Shared"

        $MonitoringVars = @{
            resource_group_name = $ResourceGroupName
            location = $Location
            subscription_id = $SubscriptionId
            openai_resource_id = $openaiId
            budget_amount = 1000
            emails_platform_team = @("platform-admins@example.com")
            emails_ai_app_team = @("app-owners@example.com")
            emails_model_ops_team = @("model-ops@example.com")
            tags = $MonitoringTags
        }
        $MonitoringVars | ConvertTo-Json -Depth 10 | Set-Content "terraform.tfvars.json"

        terraform init -upgrade
        terraform apply -auto-approve
        if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed" }
        Write-Host "Monitoring & Cost Controls Deployed." -ForegroundColor Green
    } catch {
        Write-Error "Monitoring deployment failed: $_"
        exit 1
    } finally {
        Pop-Location
    }
}

Write-Host "`nDeployment Complete!" -ForegroundColor Green
