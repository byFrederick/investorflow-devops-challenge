config {
  format = "compact"
  plugin_dir = "~/.tflint.d/plugins"
}

plugin "azurerm" {
    enabled = true
    version = "0.31.1"
    source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}
