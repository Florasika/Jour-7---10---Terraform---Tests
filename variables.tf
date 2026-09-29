variable "nom_projet" {
  description = "Nom du projet data"
  type        = string
  default     = "etl_portfolio"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.nom_projet))
    error_message = "Le nom doit commencer par une lettre et contenir uniquement des lettres minuscules, chiffres et underscores."
  }
}

variable "environnement" {
  description = "Environnement cible"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environnement)
    error_message = "Valeurs autorisées : dev, staging, prod."
  }
}

variable "version_app" {
  description = "Version de l'application (format semver)"
  type        = string
  default     = "1.0.0"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.version_app))
    error_message = "La version doit suivre le format semver : X.Y.Z"
  }
}
