data "sops_file" "secrets" {
  for_each = fileexists("${path.module}/data/secrets.sops.yml") ? toset(["default"]) : toset([])

  source_file = "${path.module}/data/secrets.sops.yml"
}
