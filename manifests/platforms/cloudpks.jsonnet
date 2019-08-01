
// Top-level file for Cloud PKS
// Note: DNS and oauth components are commented out for development purpposes

local kube = import "../lib/kube.libsonnet";
local utils = import "../lib/utils.libsonnet";
local version = import "../components/version.jsonnet";
local cert_manager = import "../components/cert-manager.jsonnet";
// local edns = import "../components/externaldns.jsonnet";
local nginx_ingress = import "../components/nginx-ingress.jsonnet";
local prometheus = import "../components/prometheus.jsonnet";
// local oauth2_proxy = import "../components/oauth2-proxy.jsonnet";
local fluentd_es = import "../components/fluentd-es.jsonnet";
local elasticsearch = import "../components/elasticsearch.jsonnet";
local kibana = import "../components/kibana.jsonnet";
local grafana = import "../components/grafana.jsonnet";

{
  config:: error "no kubeprod configuration",

  // Shared metadata for all components
  kubeprod: kube.Namespace("kubeprod"),

  external_dns_zone_name:: $.config.dnsZone,
  letsencrypt_contact_email:: $.config.contactEmail,
  // Using letsencrypt stage for development purposes
  letsencrypt_environment:: "stage",

  version: version,

  grafana: grafana {
    prometheus:: $.prometheus.prometheus.svc,
    ingress+: {
      host: "grafana." + $.external_dns_zone_name,
    },
  },

/*

  edns: edns {
    gcreds: utils.HashedSecret($.edns.p+"external-dns-google-credentials") + $.edns.metadata {
      data_+: {
        "credentials.json": $.config.externalDns.credentials,
      },
    },

    deploy+: {
      ownerId: $.external_dns_zone_name,
      spec+: {
        template+: {
          spec+: {
            volumes_+: {
              gcreds: kube.SecretVolume($.edns.gcreds),
            },
            containers_+: {
              edns+: {
                args_+: {
                  provider: "google",
                  "google-project": $.config.externalDns.project,
                },
                env_+: {
                  GOOGLE_APPLICATION_CREDENTIALS: "/google/credentials.json",
                },
                volumeMounts_+: {
                  gcreds: {mountPath: "/google", readOnly: true},
                },
              },
            },
          },
        },
      },
    },
  },
  */


  cert_manager: cert_manager {
    letsencrypt_contact_email:: $.letsencrypt_contact_email,
    letsencrypt_environment:: $.letsencrypt_environment,
  },

  nginx_ingress: nginx_ingress,

  /*

  oauth2_proxy: oauth2_proxy {
  local oauth2 = self,

    secret+: {
      data_+: $.config.oauthProxy,
    },

    ingress+: {
      host: "auth." + $.external_dns_zone_name,
    },

    gcreds: utils.HashedSecret(oauth2.p+"oauth2-proxy-google-credentials") + oauth2.metadata {
      data_+: {
        "credentials.json": $.config.oauthProxy.google_service_account_json,
      },
    },
  
    deploy+: {
      spec+: {
        template+: {
          spec+: {
            volumes_+: {
              gcreds: kube.SecretVolume(oauth2.gcreds),
            },
            containers_+: {
              proxy+: {
                args_+: {
                  "email-domain": $.config.oauthProxy.authz_domain,
                  provider: "google",
                  "google-service-account-json": if $.config.oauthProxy.google_service_account_json != "" then "/google/credentials.json" else "",
                  "google-admin-email": $.config.oauthProxy.google_admin_email,
                  google_groups_:: $.config.oauthProxy.google_groups,
                },
                args+: ["--google-group=" + g for g in std.set(self.args_.google_groups_)],
                volumeMounts_+: {
                  gcreds: {mountPath: "/google", readOnly: true},
                },
              },
            },
          },
        },
      },
    },
  },

*/

  prometheus: prometheus {
    ingress+: {
      host: "prometheus." + $.external_dns_zone_name,
    },
  },

  fluentd_es: fluentd_es {
    es:: $.elasticsearch,
  },

  elasticsearch: elasticsearch,

  kibana: kibana {
    es:: $.elasticsearch,

    ingress+: {
      host: "kibana." + $.external_dns_zone_name,
    },
  },
}
