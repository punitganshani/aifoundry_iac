resource "azurerm_policy_set_definition" "mandatory_tags" {
  name         = "enforce-mandatory-tags"
  policy_type  = "Custom"
  display_name = "Enforce Mandatory Tags for AI Foundry"
  description  = "Enforces the presence of AppId, CostCenter, Environment, Tier, DataClassification, and DR-Approved tags."

  metadata = <<METADATA
    {
      "category": "Tags"
    }
  METADATA

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_tag.id
    parameter_values     = <<VALUE
      {
        "tagName": {"value": "AppId"}
      }
    VALUE
    reference_id         = "require-AppId"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_tag.id
    parameter_values     = <<VALUE
      {
        "tagName": {"value": "CostCenter"}
      }
    VALUE
    reference_id         = "require-CostCenter"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_tag.id
    parameter_values     = <<VALUE
      {
        "tagName": {"value": "Environment"}
      }
    VALUE
    reference_id         = "require-Environment"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_tag.id
    parameter_values     = <<VALUE
      {
        "tagName": {"value": "Tier"}
      }
    VALUE
    reference_id         = "require-Tier"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_tag.id
    parameter_values     = <<VALUE
      {
        "tagName": {"value": "DataClassification"}
      }
    VALUE
    reference_id         = "require-DataClassification"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_tag.id
    parameter_values     = <<VALUE
      {
        "tagName": {"value": "DR-Approved"}
      }
    VALUE
    reference_id         = "require-DR-Approved"
  }
}
