plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

config {
  force = false
}

rule terraform_naming_convention {
  enabled = true
}

rule terraform_documented_outputs {
  enabled = true
}

rule terraform_documented_variables {
  enabled = true
}

rule terraform_module_pinned_source {
  enabled = false
}
