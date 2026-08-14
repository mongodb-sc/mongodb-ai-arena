locals {
  # Base Nginx configuration
  base_nginx_config = templatefile("${path.module}/nginx-conf-files/nginx-base-config.conf.tpl", {})

  # Per-user nginx config map: user_id => rendered config
  nginx_user_config_map = {
    for user_id in local.atlas_user_list : user_id => templatefile("${path.module}/nginx-conf-files/mdb-nginx-openvscode.conf.tpl", {
      server_name   = "${user_id}.${local.aws_route53_record_name}",
      data_username = user_id,
      proxy_pass    = lookup(data.kubernetes_service.openvscode_services[user_id].metadata[0], "name", "default-ip")
    })
  }

  # Chunk users into groups of 100 to keep each ConfigMap well under the 1 MiB limit
  nginx_user_chunks = chunklist(local.atlas_user_list, 100)

  index_nginx_html = templatefile("${path.module}/nginx-html-files/index.html.tpl", {
    customer_name = lower(var.customer_name),
    server_name   = local.aws_route53_record_name
  })

  notfound_nginx_html = templatefile("${path.module}/nginx-html-files/404.html.tpl", {
    customer_name = lower(var.customer_name),
    server_name   = local.aws_route53_record_name
  })

  error_nginx_html = templatefile("${path.module}/nginx-html-files/50x.html.tpl", {
    customer_name = lower(var.customer_name),
    server_name   = local.aws_route53_record_name
  })

  # Collect all ConfigMap names for the Helm chart
  nginx_config_map_names = concat(
    ["mdb-nginx-base-config-cm"],
    [for idx in range(length(local.nginx_user_chunks)) : "mdb-nginx-user-config-cm-${idx}"]
  )

  # Checksum of all nginx server-block configs (base + per-user). Used as a pod
  # annotation so that any change to the ConfigMap contents (e.g. adding a new
  # user) forces a rolling restart of the mdb-nginx Deployment. Without this,
  # Kubernetes only updates the mounted ConfigMap files on disk but never
  # signals the already-running nginx process to reload them.
  nginx_config_checksum = sha256(jsonencode(merge(
    { "00-base.conf" = local.base_nginx_config },
    local.nginx_user_config_map
  )))
}

# ConfigMap for the base nginx config (default server, SSL, health check)
resource "kubernetes_config_map" "nginx_base_config" {
  metadata {
    name      = "mdb-nginx-base-config-cm"
    namespace = "default"
  }

  data = {
    "00-base.conf" = local.base_nginx_config
  }

  depends_on = [
    helm_release.user_openvscode
  ]
}

# Chunked ConfigMaps for per-user nginx server blocks
resource "kubernetes_config_map" "nginx_user_configs" {
  count = length(local.nginx_user_chunks)

  metadata {
    name      = "mdb-nginx-user-config-cm-${count.index}"
    namespace = "default"
  }

  data = {
    for user_id in local.nginx_user_chunks[count.index] :
    "${user_id}.conf" => local.nginx_user_config_map[user_id]
  }

  depends_on = [
    helm_release.user_openvscode
  ]
}

resource "kubernetes_secret" "nginx_tls_secret" {
  metadata {
    name      = "nginx-tls-secret"
    namespace = "default"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = "${acme_certificate.mongosa_cert.certificate_pem}${acme_certificate.mongosa_cert.issuer_pem}"
    "tls.key" = tls_private_key.request_key.private_key_pem
  }

  depends_on = [ 
    acme_certificate.mongosa_cert, 
    tls_private_key.request_key 
  ]
}

resource "helm_release" "airbnb_arena_nginx" {
  name       = "mdb-nginx"
  repository = "local"
  chart      = "./mdb-nginx"
  version    = "0.3.0"

  values = [
    file("${path.module}/mdb-nginx/values.yaml"),
    yamlencode({
      volumeMounts = [
        {
          name      = "custom-nginx-conf",
          mountPath = "/etc/nginx/nginx.conf",
          subPath   = "nginx.conf",
          readOnly  = true
        },
        {
          name      = "nginx-html-volume",
          mountPath = "/usr/share/nginx/html"
        },
        {
          name      = "nginx-tls-secret",
          mountPath = "/etc/nginx/ssl",
          readOnly  = true
        }
      ],
      volumes = [
        {
          name = "custom-nginx-conf",
          configMap = {
            name = "mdb-nginx-cm"
          }
        },
        {
          name = "nginx-html-volume",
          configMap = {
            name = "mdb-nginx-html-cm"
          }
        },
        {
          name = "nginx-tls-secret",
          secret = {
            secretName = "nginx-tls-secret"
          }
        }
      ],
      # List of ConfigMap names projected into /etc/nginx/conf.d/
      nginxConfigMaps = local.nginx_config_map_names,
      # Forces a rolling restart of the mdb-nginx pods whenever any nginx
      # server-block config changes (e.g. a user is added/removed), since
      # Kubernetes does not otherwise restart pods on ConfigMap data changes.
      podAnnotations = {
        "checksum/nginx-config" = local.nginx_config_checksum
      },
      nginx = {
        conf     = file("${path.module}/nginx-conf-files/nginx.conf")
        notfound = local.notfound_nginx_html
        html     = local.index_nginx_html
        error    = local.error_nginx_html
        favicon  = filebase64("${path.module}/nginx-html-files/favicon.ico")
      }
    })
  ]

  depends_on = [
    helm_release.user_openvscode,
    kubernetes_secret.nginx_tls_secret,
    kubernetes_config_map.nginx_base_config,
    kubernetes_config_map.nginx_user_configs
  ]
}

data "kubernetes_service" "nginx_service" {
  metadata {
    name      = helm_release.airbnb_arena_nginx.name
    namespace = helm_release.airbnb_arena_nginx.namespace
  }

  depends_on = [
    helm_release.airbnb_arena_nginx
  ]
}

output "nginx_service_hostname" {
  value = data.kubernetes_service.nginx_service.status[0].load_balancer[0].ingress[0].hostname
}

locals {
  hostname_parts = split("-", data.kubernetes_service.nginx_service.status[0].load_balancer[0].ingress[0].hostname)
  short_hostname = join("-", slice(local.hostname_parts, 0, 4))
}

data "aws_lb" "nginx_lb" {
  name = local.short_hostname

  depends_on = [ 
    data.kubernetes_service.nginx_service
  ]
}

output "zone_id" {
  value = data.aws_lb.nginx_lb.zone_id
}
