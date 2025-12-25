resource "azurerm_policy_definition" "allowed_models" {
  name         = "allowed-models"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Allowed OpenAI Models"
  description  = "Restricts which OpenAI models can be deployed."

  metadata = <<METADATA
    {
      "category": "Cognitive Services"
    }
  METADATA

  policy_rule = <<POLICY_RULE
    {
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.CognitiveServices/accounts/deployments"
          },
          {
            "not": {
              "field": "Microsoft.CognitiveServices/accounts/deployments/model.name",
              "in": "[parameters('allowedModelNames')]"
            }
          }
        ]
      },
      "then": {
        "effect": "Deny"
      }
    }
  POLICY_RULE

  parameters = <<PARAMETERS
    {
      "allowedModelNames": {
        "type": "Array",
        "metadata": {
          "displayName": "Allowed Model Names",
          "description": "The list of allowed model names (e.g., gpt-4o, gpt-35-turbo)."
        },
        "defaultValue": ["gpt-4o", "gpt-4", "gpt-35-turbo", "text-embedding-ada-002"]
      }
    }
  PARAMETERS
}
