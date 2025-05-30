resource "github_repository" "tf" {
  for_each               = var.tf_module_repos
  name                   = "tf-${replace(lower(each.key), " ", "")}"
  visibility             = "internal"
  delete_branch_on_merge = true
  allow_auto_merge       = true
  topics                 = ["terraform", "terraform-module"]

  lifecycle {
    ignore_changes = [
      description
    ]
  }
}

resource "github_repository_collaborators" "tf" {
  for_each   = var.tf_module_repos
  repository = github_repository.tf[each.value].name
  team {
    team_id    = github_team.team["Example Team"].slug
    permission = "push"
  }
}