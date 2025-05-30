locals {
  members = setsubtract(toset(flatten(
    concat(
      [for team in var.teams : team.members != null ? team.members : []],
      [for team in var.teams : team.admins != null ? team.admins : []]
  ))), var.org_admins)

}

resource "github_organization_settings" "org" {
  name                                    = "Organization Name"
  billing_email                           = "billing@email.com"
  blog                                    = ""
  default_repository_permission           = "none"
  has_organization_projects               = false
  has_repository_projects                 = false
  members_can_create_private_repositories = false
  members_can_create_public_repositories  = false
  members_can_create_repositories         = false
}

resource "github_organization_ruleset" "master-branch-protection" {
  name        = "Master Branch Protection"
  target      = "branch"
  enforcement = "active"

  bypass_actors {
    actor_id    = 0
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  conditions {
    ref_name {
      exclude = []
      include = [
        "~DEFAULT_BRANCH",
      ]
    }

    repository_name {
      exclude = []
      include = [
        "~ALL",
      ]
      protected = false
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true
    pull_request {
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_approving_review_count   = 1
      required_review_thread_resolution = false
    }
  }
}

resource "github_repository" "github-enterprise" {
  name                   = "github-enterprise"
  visibility             = "internal"
  delete_branch_on_merge = true
}

resource "github_repository_collaborator" "github-enterprise" {
  for_each   = local.members
  repository = github_repository.github-enterprise.name
  username   = each.value
  permission = "push"
}

resource "github_repository" "discussions" {
  name                   = "discussions"
  visibility             = "internal"
  has_discussions        = true
  delete_branch_on_merge = true
}

resource "github_repository" "github-public" {
  name                   = ".github"
  visibility             = "public"
  vulnerability_alerts   = true
  delete_branch_on_merge = true
}

resource "github_repository" "github-private" {
  name                   = ".github-private"
  visibility             = "private"
  vulnerability_alerts   = true
  delete_branch_on_merge = true
}

resource "github_membership" "admin" {
  for_each = var.org_admins
  username = each.value
  role     = "admin"
}

resource "github_membership" "member" {
  for_each = local.members
  username = each.value
  role     = "member"
}
