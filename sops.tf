locals {
  # Shared shell script used by shell_sensitive_script resources before GitHub writes.
  sops_script_encrypt = file("${path.module}/templates/scripts/sops_encrypt.sh")

  # Optional SOPS-encrypted overrides for provided or externally generated
  # secrets. Generated secrets still come from provider/runtime resources.
  sops_secrets = try(yamldecode(data.sops_file.secrets["default"].raw), {})
}

data "sops_file" "secrets" {
  for_each = fileexists("${path.module}/data/secrets.sops.yml") ? toset(["default"]) : toset([])

  source_file = "${path.module}/data/secrets.sops.yml"
}
