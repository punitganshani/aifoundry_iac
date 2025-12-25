resource "azurerm_policy_definition" "deny_public_endpoints" {
  name         = "deny-public-endpoints"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Deny Public Network Access"
  description  = "Denies creation of resources with public network access enabled."

  metadata = <<METADATA
    {
      "category": "Network"
    }
  METADATA

  policy_rule = <<POLICY_RULE
    {
      "if": {
        "allOf": [
          {
            "field": "Microsoft.CognitiveServices/accounts/publicNetworkAccess",
            "equals": "Enabled"
          },
          {
            "field": "Microsoft.CognitiveServices/accounts/networkAcls.defaultAction",
            "notEquals": "Deny"
          }
        ]
      },
      "then": {
        "effect": "deny"
      }
    }
  POLICY_RULE
}
