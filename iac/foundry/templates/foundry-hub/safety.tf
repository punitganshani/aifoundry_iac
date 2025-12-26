# ---------------------------------------------------------
# Safety Policy Implementation (Security Baseline)
# ---------------------------------------------------------
resource "azurerm_cognitive_account_rai_policy" "security_policy" {
  name                  = "security-baseline"
  cognitive_account_id  = azurerm_cognitive_account.hub_openai.id
  base_policy_name      = "Microsoft.Default"
  
  # Hate
  content_filter {
    name              = "Hate"
    filter_enabled    = true
    block_enabled     = true
    severity_threshold = "Medium"
    source            = "Prompt"
  }

  content_filter {
    name              = "Hate"
    filter_enabled    = true
    block_enabled     = true
    severity_threshold = "Medium"
    source            = "Completion"
  }

  # Sexual
  content_filter {
    name              = "Sexual"
    filter_enabled    = true
    block_enabled     = true
    severity_threshold = "Medium"
    source            = "Prompt"
  }
  content_filter {
    name              = "Sexual"
    filter_enabled    = true
    block_enabled     = true
    severity_threshold = "Medium"
    source            = "Completion"
  }

  # Violence
  content_filter {
    name              = "Violence"
    filter_enabled    = true
    block_enabled     = true
    severity_threshold = "Medium"
    source            = "Prompt"
  }
  content_filter {
    name              = "Violence"
    filter_enabled    = true
    block_enabled     = true
    severity_threshold = "Medium"
    source            = "Completion"
  }

  # SelfHarm
  content_filter {
    name              = "SelfHarm"
    filter_enabled    = true
    block_enabled     = true
    severity_threshold = "Medium"
    source            = "Prompt"
  }
  content_filter {
    name              = "SelfHarm"
    filter_enabled    = true
    block_enabled     = true
    severity_threshold = "Medium"
    source            = "Completion"
  }
  # Prompt Shields (Jailbreak & Indirect Attack)
  content_filter {
    name           = "Jailbreak"
    filter_enabled = true
    block_enabled  = true
    severity_threshold = "Medium" # Required by TF provider, ignored by API for this type https://github.com/hashicorp/terraform-provider-azurerm/issues/28653
    source         = "Prompt"
  }
  content_filter {
    name           = "Indirect Attack"
    filter_enabled = true
    block_enabled  = true
    severity_threshold = "Medium" # Required by TF provider https://github.com/hashicorp/terraform-provider-azurerm/issues/28653
    source         = "Prompt"
  }

  # Protected Material
  content_filter {
    name           = "Protected Material Text"
    filter_enabled = true
    block_enabled  = true
    severity_threshold = "Medium" # Required by TF provider https://github.com/hashicorp/terraform-provider-azurerm/issues/28653
    source         = "Completion"
  }
  content_filter {
    name           = "Protected Material Code"
    filter_enabled = true
    block_enabled  = true
    severity_threshold = "Medium" # Required by TF provider https://github.com/hashicorp/terraform-provider-azurerm/issues/28653
    source         = "Completion"
  }

  # ---------------------------------------------------------
  # PII (Personally Identifiable Information)
  # ---------------------------------------------------------
  # Note: PII blocking requires the "Pii" content filter to be available in the region.
  # If not available, this block may need to be removed or adjusted.
  # content_filter {
  #   name           = "Pii"
  #   filter_enabled = true
  #   block_enabled  = true
  #   severity_threshold = "High"
  #   source         = "Prompt"
  # }
  # content_filter {
  #   name           = "Pii"
  #   filter_enabled = true
  #   block_enabled  = true
  #   severity_threshold = "High"
  #   source         = "Completion"
  # }

  # Groundedness (Preview) - Not supported in current region/SKU or API version
  # content_filter {
  #   name           = "Groundedness"
  #   filter_enabled = true
  #   block_enabled  = true
  #   severity_threshold = "Medium" # Required by TF provider https://github.com/hashicorp/terraform-provider-azurerm/issues/28653
  #   source         = "Completion"
  # }

  # Profanity / Blocklist
  content_filter {
    name           = "Profanity"
    filter_enabled = true
    block_enabled  = true
    severity_threshold = "Medium" # Required by TF provider https://github.com/hashicorp/terraform-provider-azurerm/issues/28653
    source         = "Prompt"
  }
}

# ---------------------------------------------------------
# Custom Blocklist: Financial Fraud Terms
# ---------------------------------------------------------
resource "azapi_resource" "fraud_terms" {
  type      = "Microsoft.CognitiveServices/accounts/raiBlocklists@2024-06-01-preview"
  name      = "financial-fraud-terms"
  parent_id = azurerm_cognitive_account.hub_openai.id
  
  body = jsonencode({
    properties = {
      description = "Block known fraud/scam terminology"
    }
  })
}