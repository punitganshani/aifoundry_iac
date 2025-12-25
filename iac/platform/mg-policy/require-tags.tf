resource "azurerm_policy_definition" "require_tag" {
  name         = "require-tag"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require a tag on resources"
  description  = "Requires a resource to have a specified tag."

  metadata = <<METADATA
    {
      "category": "Tags"
    }
  METADATA

  parameters = <<PARAMETERS
    {
      "tagName": {
        "type": "String",
        "metadata": {
          "displayName": "Tag Name",
          "description": "Name of the tag, such as 'environment'"
        }
      }
    }
  PARAMETERS

  policy_rule = <<POLICY_RULE
    {
      "if": {
        "allOf": [
          {
            "field": "[concat('tags[', parameters('tagName'), ']')]",
            "exists": "false"
          },
          {
            "value": "[length(split(field('type'), '/'))]",
            "lessOrEquals": 2
          }
        ]
      },
      "then": {
        "effect": "deny"
      }
    }
  POLICY_RULE
}
