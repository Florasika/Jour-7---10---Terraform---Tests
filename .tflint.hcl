# ============================================================
#  Configuration tflint — linter Terraform
#  Fichier : .tflint.hcl
# ============================================================

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Règles activées
rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_documented_variables" {
  enabled = true   # toutes les variables doivent avoir une description
}

rule "terraform_documented_outputs" {
  enabled = true   # tous les outputs doivent avoir une description
}
