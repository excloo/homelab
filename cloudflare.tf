data "cloudflare_account" "default" {
  filter = {
    name = local.defaults.cloudflare.account_name
  }
}

data "cloudflare_account_api_token_permission_groups_list" "dns_write" {
  account_id = data.cloudflare_account.default.id
  max_items  = 1
  name       = "DNS%20Write"
  scope      = "com.cloudflare.api.account.zone"
}

data "cloudflare_account_api_token_permission_groups_list" "tunnel_read" {
  account_id = data.cloudflare_account.default.id
  max_items  = 1
  name       = "Cloudflare%20Tunnel%20Read"
  scope      = "com.cloudflare.api.account"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "server" {
  for_each = local.servers_outputs_by_feature.cloudflare_zero_trust_tunnel

  account_id = data.cloudflare_account.default.id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.server[each.key].id
}

data "cloudflare_zone" "all" {
  for_each = local.dns_input

  filter = {
    name = each.key
  }
}

resource "cloudflare_account_token" "server_acme" {
  for_each = local.servers_outputs_by_feature.cloudflare_acme_token

  account_id = data.cloudflare_account.default.id
  name       = each.key

  policies = [
    {
      effect = "allow"
      permission_groups = [
        {
          id = one(data.cloudflare_account_api_token_permission_groups_list.dns_write.result).id
        }
      ]
      resources = jsonencode({
        "com.cloudflare.api.account.zone.${data.cloudflare_zone.all[local.defaults.domains.acme].zone_id}" = "*"
      })
    }
  ]
}

resource "cloudflare_account_token" "server_tunnel_read" {
  for_each = local.servers_outputs_by_feature.cloudflare_zero_trust_tunnel

  account_id = data.cloudflare_account.default.id
  name       = "${each.key}-tunnel-read"

  policies = [
    {
      effect = "allow"
      permission_groups = [
        {
          id = one(data.cloudflare_account_api_token_permission_groups_list.tunnel_read.result).id
        }
      ]
      resources = jsonencode({
        "com.cloudflare.api.account.${data.cloudflare_account.default.id}" = "*"
      })
    }
  ]
}

resource "cloudflare_dns_record" "acme_delegation" {
  for_each = local.dns_records_acme_delegation

  comment = local.defaults.organization.managed_comment
  content = each.value.content
  name    = each.value.name
  proxied = local.defaults_dns.proxied
  ttl     = local.defaults_dns.ttl
  type    = each.value.type
  zone_id = data.cloudflare_zone.all[each.value.zone].zone_id
}

resource "cloudflare_dns_record" "manual" {
  for_each = local.dns_records_manual

  comment  = local.defaults.organization.managed_comment
  content  = each.value.content
  name     = each.value.name
  priority = each.value.priority
  proxied  = each.value.proxied
  ttl      = each.value.ttl
  type     = each.value.type
  zone_id  = data.cloudflare_zone.all[each.value.zone].zone_id
}

resource "cloudflare_dns_record" "server" {
  for_each = local.dns_records_servers

  comment = local.defaults.organization.managed_comment
  content = each.value.content
  name    = each.value.name
  proxied = each.value.proxied
  ttl     = local.defaults_dns.ttl
  type    = each.value.type
  zone_id = data.cloudflare_zone.all[each.value.zone].zone_id
}

resource "cloudflare_dns_record" "service" {
  for_each = local.dns_records_services

  comment = local.defaults.organization.managed_comment
  content = each.value.content
  name    = each.value.name
  proxied = each.value.proxied
  ttl     = local.defaults_dns.ttl
  type    = each.value.type
  zone_id = data.cloudflare_zone.all[each.value.zone].zone_id
}

resource "cloudflare_dns_record" "service_fly" {
  for_each = local.dns_records_services_fly

  comment = local.defaults.organization.managed_comment
  content = each.value.content
  name    = each.value.name
  proxied = each.value.proxied
  ttl     = local.defaults_dns.ttl
  type    = each.value.type
  zone_id = data.cloudflare_zone.all[each.value.zone].zone_id
}

resource "cloudflare_dns_record" "service_url" {
  for_each = local.dns_records_services_urls

  comment = local.defaults.organization.managed_comment
  content = each.value.content
  name    = each.value.name
  proxied = each.value.proxied
  ttl     = local.defaults_dns.ttl
  type    = each.value.type
  zone_id = data.cloudflare_zone.all[each.value.zone].zone_id
}

resource "cloudflare_dns_record" "wildcard" {
  for_each = local.dns_records_wildcards

  comment = local.defaults.organization.managed_comment
  content = each.value.content
  name    = each.value.name
  proxied = each.value.proxied
  ttl     = local.defaults_dns.ttl
  type    = each.value.type
  zone_id = data.cloudflare_zone.all[each.value.zone].zone_id
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "server" {
  for_each = local.servers_outputs_by_feature.cloudflare_zero_trust_tunnel

  account_id = data.cloudflare_account.default.id
  config_src = "cloudflare"
  name       = each.key
}
