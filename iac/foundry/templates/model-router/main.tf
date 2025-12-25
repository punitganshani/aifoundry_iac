provider "azurerm" {
  features {}
}

resource "azurerm_api_management_api" "model_router" {
  name                = "ai-model-router"
  resource_group_name = var.resource_group_name
  api_management_name = var.apim_name
  revision            = "1"
  display_name        = "AI Model Router"
  path                = "openai"
  protocols           = ["https"]

  import {
    content_format = "openapi"
    content_value  = file("${path.module}/openai-swagger.json")
  }
}

resource "azurerm_api_management_api_policy" "router_policy" {
  api_name            = azurerm_api_management_api.model_router.name
  api_management_name = var.apim_name
  resource_group_name = var.resource_group_name

  xml_content = <<XML
<policies>
    <inbound>
        <base />
        <set-backend-service base-url="${var.openai_endpoint}" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
XML
}


