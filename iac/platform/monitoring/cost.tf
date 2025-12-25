resource "azurerm_monitor_action_group" "platform_team" {
  name                = "ai-governance-ag-platform"
  resource_group_name = var.resource_group_name
  short_name          = "Platform"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.emails_platform_team
    content {
      name          = "PlatformAdmin-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }
}

resource "azurerm_monitor_action_group" "ai_app_team" {
  name                = "ai-governance-ag-app"
  resource_group_name = var.resource_group_name
  short_name          = "AIApp"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.emails_ai_app_team
    content {
      name          = "AppOwner-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }
}

resource "azurerm_monitor_action_group" "model_ops_team" {
  name                = "ai-governance-ag-modelops"
  resource_group_name = var.resource_group_name
  short_name          = "ModelOps"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.emails_model_ops_team
    content {
      name          = "ModelOps-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }
}

resource "azurerm_consumption_budget_resource_group" "rg_budget" {
  name              = "ai-governance-budget"
  resource_group_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"

  amount     = var.budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = "2025-12-01T00:00:00Z"
  }

  filter {
    dimension {
      name = "ResourceId"
      values = [
        "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
      ]
    }
  }

  notification {
    enabled   = true
    threshold = 80.0
    operator  = "EqualTo"
    contact_groups = [
      azurerm_monitor_action_group.ai_app_team.id,
      azurerm_monitor_action_group.model_ops_team.id
    ]
  }

  notification {
    enabled   = true
    threshold = 100.0
    operator  = "GreaterThanOrEqualTo"
    contact_groups = [
      azurerm_monitor_action_group.platform_team.id,
      azurerm_monitor_action_group.ai_app_team.id,
      azurerm_monitor_action_group.model_ops_team.id
    ]
  }
}

# ---------------------------------------------------------
# Cost Saving Automation (Nightly Shutdown)
# ---------------------------------------------------------
resource "azurerm_user_assigned_identity" "cost_saver" {
  name                = "ai-governance-id-cost-saver"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "cost_saver_contributor" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.cost_saver.principal_id
}

resource "azurerm_logic_app_workflow" "stop_computes" {
  name                = "ai-governance-logic-stop-computes"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cost_saver.id]
  }
}

resource "azurerm_logic_app_trigger_recurrence" "nightly" {
  name         = "nightly-trigger"
  logic_app_id = azurerm_logic_app_workflow.stop_computes.id
  frequency    = "Day"
  interval     = 1
  start_time   = "2024-01-01T19:00:00Z"
}

resource "azurerm_logic_app_action_custom" "query_computes" {
  name         = "Query_Compute_Instances"
  logic_app_id = azurerm_logic_app_workflow.stop_computes.id

  body = <<BODY
{
    "type": "Http",
    "inputs": {
        "method": "POST",
        "uri": "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01",
        "body": {
            "query": "Resources | where type =~ 'microsoft.machinelearningservices/workspaces/computes' | where resourceGroup =~ '${var.resource_group_name}' | project id"
        },
        "authentication": {
            "type": "ManagedServiceIdentity",
            "identity": "${azurerm_user_assigned_identity.cost_saver.id}"
        }
    }
}
BODY
}

resource "azurerm_logic_app_action_custom" "parse_computes" {
  name         = "Parse_Computes"
  logic_app_id = azurerm_logic_app_workflow.stop_computes.id
  depends_on   = [azurerm_logic_app_action_custom.query_computes]

  body = <<BODY
{
    "type": "ParseJson",
    "inputs": {
        "content": "@body('Query_Compute_Instances')?['data']",
        "schema": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "id": {
                        "type": "string"
                    }
                }
            }
        }
    },
    "runAfter": {
        "Query_Compute_Instances": [
            "Succeeded"
        ]
    }
}
BODY
}

resource "azurerm_logic_app_action_custom" "foreach_compute" {
  name         = "For_Each_Compute"
  logic_app_id = azurerm_logic_app_workflow.stop_computes.id
  depends_on   = [azurerm_logic_app_action_custom.parse_computes]

  body = <<BODY
{
    "type": "Foreach",
    "foreach": "@body('Parse_Computes')",
    "actions": {
        "Stop_Compute": {
            "type": "Http",
            "inputs": {
                "method": "POST",
                "uri": "https://management.azure.com@{item()['id']}/stop?api-version=2024-04-01",
                "authentication": {
                    "type": "ManagedServiceIdentity",
                    "identity": "${azurerm_user_assigned_identity.cost_saver.id}"
                }
            }
        }
    },
    "runAfter": {
        "Parse_Computes": [
            "Succeeded"
        ]
    }
}
BODY
}

