locals {
  # Bitwarden custom fields store scalar values only. Empty/default fields are
  # skipped, *_sensitive fields become hidden values, and URL-like fields become
  # URI entries instead.
  bitwarden_server_fields = {
    for server_key, server in local.servers_outputs_private : server_key => {
      for field_name, field_value in server : field_name => field_value
      if field_value != null && field_value != "" && field_value != false && !can(regex(local.defaults.bitwarden.url_field_pattern, field_name)) && !contains(keys(local.defaults_server), field_name) && can(tostring(field_value))
    }
  }

  bitwarden_server_uris = {
    for server_key, server in local.servers_outputs_private : server_key => merge(
      {
        for field_name, field_value in server : field_name => field_value
        if field_value != null && field_value != "" && field_value != false && can(regex(local.defaults.bitwarden.url_field_pattern, field_name)) && can(tostring(field_value))
      },
      server.networking.management_address != "" ? {
        management_address = server.networking.management_address
      } : {}
    )
  }

  bitwarden_service_fields = {
    for service_key, service in local.services_outputs_private : service_key => {
      for field_name, field_value in service : field_name => field_value
      if field_value != null && field_value != "" && field_value != false && !can(regex(local.defaults.bitwarden.url_field_pattern, field_name)) && !contains(keys(local.defaults_service), field_name) && can(tostring(field_value))
    }
  }

  bitwarden_service_items = {
    for service_key, service in local.services_model_desired : service_key => service
    if anytrue([for feature_name, feature_enabled in service.features : tobool(feature_enabled) if can(tobool(feature_enabled))]) || length(service.features.secrets) > 0 || service.networking.scheme != null
  }

  bitwarden_service_uris = {
    for service_key, service in local.services_outputs_private : service_key => {
      for field_name, field_value in service : field_name => field_value
      if field_value != null && field_value != "" && field_value != false && can(regex(local.defaults.bitwarden.url_field_pattern, field_name)) && can(tostring(field_value))
    }
  }
}

data "bitwarden_org_collection" "servers" {
  organization_id = data.bitwarden_organization.default.id
  search          = local.defaults.bitwarden.collections.servers
}

data "bitwarden_org_collection" "services" {
  organization_id = data.bitwarden_organization.default.id
  search          = local.defaults.bitwarden.collections.services
}

data "bitwarden_organization" "default" {
  search = local.defaults.bitwarden.organization
}

resource "bitwarden_item_login" "server" {
  for_each = local.servers_model_desired

  collection_ids  = [data.bitwarden_org_collection.servers.id]
  name            = each.key
  organization_id = data.bitwarden_organization.default.id
  password        = local.servers_outputs_private[each.key].password_sensitive
  username        = local.servers_outputs_private[each.key].identity.username

  dynamic "field" {
    for_each = local.bitwarden_server_fields[each.key]

    content {
      hidden = endswith(field.key, "_sensitive") ? field.value : null
      name   = trimsuffix(field.key, "_sensitive")
      text   = endswith(field.key, "_sensitive") ? null : field.value
    }
  }

  # Bitwarden URI matching expects host-style values; IPv6 literals need brackets
  # and non-standard management ports are appended.
  dynamic "uri" {
    for_each = local.bitwarden_server_uris[each.key]

    content {
      match = "host"
      value = format(
        "%s%s",
        can(cidrhost("${uri.value}/128", 0)) ? "[${uri.value}]" : uri.value,
        local.servers_outputs_private[each.key].networking.management_port != 443 ? ":${local.servers_outputs_private[each.key].networking.management_port}" : ""
      )
    }
  }
}

resource "bitwarden_item_login" "service" {
  for_each = local.bitwarden_service_items

  collection_ids  = [data.bitwarden_org_collection.services.id]
  name            = "${local.services_outputs_private[each.key].identity.title} (${local.services_outputs_private[each.key].target})"
  organization_id = data.bitwarden_organization.default.id
  password        = local.services_outputs_private[each.key].password_sensitive
  username        = local.services_outputs_private[each.key].identity.username

  dynamic "field" {
    for_each = local.bitwarden_service_fields[each.key]

    content {
      hidden = endswith(field.key, "_sensitive") ? field.value : null
      name   = trimsuffix(field.key, "_sensitive")
      text   = endswith(field.key, "_sensitive") ? null : field.value
    }
  }

  # Service URI entries come from computed fqdn_/url_ fields.
  dynamic "uri" {
    for_each = local.bitwarden_service_uris[each.key]

    content {
      match = "host"
      value = uri.value
    }
  }
}
