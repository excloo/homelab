locals {
  # Merge schema defaults into each source service before expanding deploy targets.
  services_input = {
    for service_key, service in {
      for file_path in fileset(path.module, "data/services/*.yml") :
      trimsuffix(basename(file_path), ".yml") => yamldecode(file("${path.module}/${file_path}"))
    } : service_key => provider::deepmerge::mergo(local.defaults_service, service)
  }

  # Each deploy_to target becomes its own stack, so target-specific secrets and
  # rendered files have stable addresses like service-target.
  services_input_targets = merge([
    for service_key, service in local.services_input : {
      for target in service.deploy_to : "${service_key}-${target}" => merge(
        service,
        {
          target = target
        }
      )
    }
  ]...)
}
