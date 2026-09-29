output "configs_deployes" {
  description = "Résumé des configurations déployées"
  value = {
    for env, cfg in local.environnements :
    env => {
      replicas  = cfg.replicas
      deploy_id = random_id.deploy_id[env].hex
    }
  }
}
