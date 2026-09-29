# 🧪 Jour 7 / 10 — Terraform : Tests

> **Série : 10 Days of Terraform** · Jour 7/10  
> Concepts : terraform fmt · validate · tflint · checkov · Tests d'idempotence · GitHub Actions

---

## 📁 Fichiers du projet

```
day-07-tests/
│
├── main.tf               ← Resources à tester
├── variables.tf          ← Variables avec validations
├── outputs.tf            ← Outputs
├── .tflint.hcl           ← Config tflint (linter)
├── .checkov.yml          ← Config checkov (sécurité)
├── test_terraform.sh     ← Script de tests complet (10 tests)
├── .github/
│   └── workflows/
│       └── terraform-tests.yml  ← CI/CD des tests
└── README.md
```

---

## 🧠 Pourquoi tester du Terraform ?

```
Sans tests :
→ Un typo dans un .tf → plan échoue en production
→ Une variable sans validation → valeur invalide en prod
→ Une resource non idempotente → destroy/recreate inattendu

Avec tests :
→ fmt     : code formaté uniformément
→ validate: syntaxe correcte avant d'aller plus loin
→ tflint  : conventions et bonnes pratiques
→ checkov : sécurité (pas de secrets en dur, chiffrement...)
→ plan    : vérifier ce qui sera créé avant apply
→ idempotence : apply deux fois = même résultat
```

---

## 🚀 ÉTAPE 1 — Préparer les fichiers

```bash
mkdir -p jour7-terraform/.github/workflows
mkdir -p jour7-terraform/output
cd jour7-terraform/

# Copier les fichiers :
# main_j7.tf          → main.tf
# variables_j7.tf     → variables.tf
# outputs_j7.tf       → outputs.tf
# tflint_config.hcl   → .tflint.hcl
# checkov_config.yml  → .checkov.yml
# test_terraform.sh   → test_terraform.sh
# ci_tests.yml        → .github/workflows/terraform-tests.yml

chmod +x test_terraform.sh
```

---

## 🔑 ÉTAPE 2 — terraform fmt (format)

```bash
# Vérifier le format sans modifier
terraform fmt -check -recursive -diff .

# Corriger automatiquement
terraform fmt -recursive .

# En CI — échoue si le code n'est pas formaté
terraform fmt -check -recursive
```

**Exemple de ce que fmt corrige :**
```hcl
# Avant (mal formaté)
variable "nom" {type=string
default="dev"}

# Après terraform fmt
variable "nom" {
  type    = string
  default = "dev"
}
```

---

## 🔑 ÉTAPE 3 — terraform validate (syntaxe)

```bash
terraform init -backend=false   # init sans configurer le backend
terraform validate

# OK :
# Success! The configuration is valid.

# KO :
# Error: Reference to undeclared resource
```

---

## 🔑 ÉTAPE 4 — tflint (linter)

```bash
# Installer tflint
# Mac
brew install tflint

# Linux
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Windows
choco install tflint

# Initialiser les plugins
tflint --init

# Lancer
tflint --config=.tflint.hcl .

# Exemples d'erreurs détectées :
# Warning: variable "nom" has no description (terraform_documented_variables)
# Error:  resource name "myRes" is not snake_case (terraform_naming_convention)
```

---

## 🔑 ÉTAPE 5 — checkov (sécurité)

```bash
# Installer checkov
pip install checkov

# Scanner le dossier courant
checkov -d . --config-file .checkov.yml

# Exemples de checks :
# PASSED: CKV_TF_2 - Ensure Terraform module sources use a commit hash
# FAILED: CKV2_TF_1 - Ensure file permissions are restrictive
```

---

## 🔑 ÉTAPE 6 — Validations dans variables.tf

```hcl
variable "nom_projet" {
  type    = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.nom_projet))
    error_message = "Doit commencer par une lettre, minuscules et underscores."
  }
}

variable "version_app" {
  type    = string

  validation {
    condition     = can(regex("^[0-9]+\.[0-9]+\.[0-9]+$", var.version_app))
    error_message = "Format semver requis : X.Y.Z"
  }
}
```

```bash
# Tester une valeur invalide
terraform plan -var="nom_projet=MonProjet"
# Error: Invalid value for variable
# Le nom doit commencer par une lettre...

terraform plan -var="version_app=v1.0"
# Error: La version doit suivre le format semver : X.Y.Z
```

---

## 🚀 ÉTAPE 7 — Lancer le script de tests complet

```bash
# Créer les dossiers output
mkdir -p output/dev output/staging output/prod

# Lancer les 10 tests
bash test_terraform.sh

# Résultat attendu :
# ============================================
#   Tests Terraform — Jour 7
# ============================================
# → Test 1 : terraform fmt
# ✓ Format OK
# → Test 2 : terraform init
# ✓ Init OK
# → Test 3 : terraform validate
# ✓ Validate OK
# → Test 4 : validation des variables
# ✓ Variable invalide correctement rejetée
# → Test 5 : tflint
# ✓ tflint OK
# → Test 6 : checkov
# ✓ checkov OK
# → Test 7 : terraform plan
# ✓ Plan OK — 8 ressources à créer
# → Test 8 : apply et vérification des fichiers
# ✓ Apply OK
# ✓ Fichier output/dev/config.json créé
# ✓ Fichier output/staging/config.json créé
# ✓ Fichier output/prod/config.json créé
# ✓ JSON valide
# → Test 9 : idempotence
# ✓ Idempotent — aucun changement au 2ème plan
# → Test 10 : terraform destroy
# ✓ Destroy OK
# ============================================
#   Tous les tests passent ✓
# ============================================
```

---

## 🔑 ÉTAPE 8 — Test d'idempotence expliqué

```bash
# Premier apply
terraform apply -auto-approve

# Deuxième plan — doit retourner exit code 0 (aucun changement)
terraform plan -detailed-exitcode
# Exit code 0 = pas de changements → idempotent ✓
# Exit code 2 = changements détectés → non idempotent ✗

# Pourquoi c'est important :
# timestamp() dans les resources crée un changement à chaque plan
# → À éviter en production
```

---

## 🚀 ÉTAPE 9 — GitHub Actions

```bash
# Pousser sur GitHub → les tests se lancent automatiquement
git add .
git commit -m "tests: Terraform Day 7"
git push

# GitHub Actions → Actions → Terraform Tests
# → fmt ✓ → validate ✓ → tflint ✓ → checkov ✓ → script ✓
```

---

## 💡 Récap — La pyramide de tests Terraform

```
          [Plan/Apply]
         Test d'intégration
        ─────────────────────
       [checkov + tflint]
      Tests statiques
     ───────────────────────
    [fmt + validate]
   Tests de syntaxe
  ─────────────────────────
 Rapides → Lents
 Peu coûteux → Coûteux
```

---


---

⭐ **Si ce projet t'aide, mets une étoile !**
