resource "azurerm_portal_dashboard" "governance_dashboard" {
  name                = "ai-governance-dashboard"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  dashboard_properties = <<DASHBOARD
{
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {
            "x": 0,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "# AI Governance Overview\n\nThis dashboard tracks token usage, cost, and safety events across the AI Foundry estate."
                }
              }
            }
          }
        },
        "1": {
          "position": {
            "x": 6,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.CognitiveServices/accounts/openai-shared"
                        },
                        "name": "ProcessedInferenceTokens",
                        "aggregationType": 1,
                        "namespace": "microsoft.cognitiveservices/accounts",
                        "metricVisualization": {
                          "displayName": "Token Usage"
                        }
                      }
                    ],
                    "title": "Total Token Usage",
                    "visualization": {
                      "chartType": 2
                    }
                  }
                }
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart"
          }
        },
        "2": {
          "position": {
            "x": 0,
            "y": 4,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
                        },
                        "name": "ActualCost",
                        "aggregationType": 1,
                        "namespace": "microsoft.costmanagement/costanalysis",
                        "metricVisualization": {
                          "displayName": "Cost"
                        }
                      }
                    ],
                    "title": "Daily Cost by Service",
                    "visualization": {
                      "chartType": 2
                    },
                    "grouping": {
                      "dimension": "ServiceName",
                      "sort": 2,
                      "top": 10
                    }
                  }
                }
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart"
          }
        }
      }
    }
  },
  "metadata": {
    "model": {
      "timeRange": {
        "value": {
          "relative": {
            "duration": 24,
            "timeUnit": 1
          }
        },
        "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
      }
    }
  }
}
DASHBOARD
}

resource "azurerm_monitor_metric_alert" "safety_event_alert" {
  name                = "ai-governance-alert-safety"
  resource_group_name = var.resource_group_name
  scopes              = [var.openai_resource_id]
  description         = "Alert when content safety blocks occur"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.CognitiveServices/accounts"
    metric_name      = "BlockedCalls"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = azurerm_monitor_action_group.platform_team.id
  }

}

