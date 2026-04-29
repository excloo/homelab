locals {
  secrets_input_files = fileexists("${path.module}/data/secrets.sops.yml") ? toset(["default"]) : toset([])
}

data "sops_file" "secrets" {
  for_each = local.secrets_input_files

  source_file = "${path.module}/data/secrets.sops.yml"
}
