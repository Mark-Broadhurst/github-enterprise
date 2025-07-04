locals {
  team_repos = toset(flatten([
    for team in var.teams : [
      for repo in team.repos != null ? team.repos : [] : replace(lower("${team.alias != null ? team.alias : team.name}-${repo}"), " ", "")
    ]
  ]))
  team_members = {
    for kvp in flatten([
      for team in var.teams : concat(
        [
          for idx, member in team.members != null ? team.members : [] :
          {
            team_name   = team.name
            member_name = member
          }
        ],
        [
          for idx, admin in team.admins != null ? team.admins : [] :
          {
            team_name   = team.name
            member_name = admin
          }
        ]
      )
      ]) : "${kvp.team_name}-${kvp.member_name}" => {
      team_name   = kvp.team_name
      member_name = kvp.member_name
    }
  }
  repo_teams = {
    for kvp in flatten([
      for team in var.teams : [
        for repo in team.repos != null ? team.repos : [] : {
          team_name = team.name
          repo_name = replace(lower("${team.alias != null ? team.alias : team.name}-${repo}"), " ", "")
        }
      ]
      ]) : "${kvp.team_name}-${kvp.repo_name}" => {
      team_name = kvp.team_name
      repo_name = kvp.repo_name
    }
  }
  repo_team_details = {
    for detail in flatten([
      for team in var.teams : [
        for repo in team.repos != null ? team.repos : [] : {
          repo    = replace(lower("${team.alias != null ? team.alias : team.name}-${repo}"), " ", "")
          team    = team.name
          admins  = team.admins != null ? team.admins : []
          members = team.members != null ? team.members : []
        }
      ]
    ]) : detail.repo => detail
  }
  team_environments = { for kvp in flatten(
    [for team in var.teams : [
      for repo in team.repos != null ? team.repos : [] : [
        for name, sub_id in team.environments != null ? team.environments : {} :
        {
          team_name        = team.name
          repo_name        = replace(lower("${team.alias != null ? team.alias : team.name}-${repo}"), " ", "")
          environment_name = name
          subscription_id  = sub_id
        }
      ]
    ]]) : "${kvp.repo_name}-${kvp.environment_name}" => {
    team_name        = kvp.team_name
    repo_name        = kvp.repo_name
    environment_name = kvp.environment_name
    subscription_id  = kvp.subscription_id
    }
  }
}

resource "github_team" "team" {
  for_each = { for team in var.teams : team.name => team }
  name     = each.key
  privacy  = "closed"
}

resource "github_team_membership" "team_member" {
  for_each = local.team_members
  team_id  = github_team.team[each.value.team_name].id
  username = each.value.member_name
  role     = contains(var.org_admins, each.value.member_name) ? "maintainer" : "member"
}

resource "github_repository" "team_repo" {
  for_each               = local.team_repos
  name                   = each.key
  visibility             = "private"
  delete_branch_on_merge = true
  allow_auto_merge       = true
  vulnerability_alerts   = true

  lifecycle {
    ignore_changes = [
      pages,
      description,
      topics
    ]
  }
}

resource "github_repository_dependabot_security_updates" "sec" {
  for_each   = local.team_repos
  repository = github_repository.team_repo[each.key].name
  enabled    = true
}

resource "github_repository_collaborators" "team_collaborators" {
  for_each   = local.repo_team_details
  repository = each.key

  team {
    team_id    = github_team.team[each.value.team].id
    permission = "push"
  }

  dynamic "team" {
    for_each = each.value.team != "Cloud Enablement" ? [1] : []
    content {
      team_id    = github_team.team["Cloud Enablement"].id
      permission = "pull"
    }
  }

  dynamic "user" {
    for_each = each.value.members
    content {
      username   = user.value
      permission = "push"
    }
  }

  dynamic "user" {
    for_each = each.value.admins
    content {
      username   = user.value
      permission = "admin"
    }
  }
}

resource "github_actions_runner_group" "runner_group" {
  for_each = { for team in var.teams : team.name => team if team.repos != null && length(team.repos) > 0 }

  name       = each.key
  visibility = "selected"
  selected_repository_ids = [
    for repo in each.value.repos != null ? each.value.repos : [] :
    github_repository.team_repo[replace(lower("${each.value.alias != null ? each.value.alias : each.key}-${repo}"), " ", "")].repo_id
  ]
}

#resource "github_repository_environment" "env" {
#  for_each    = local.team_environments
#  repository  = each.value.repo_name
#  environment = each.value.environment_name
#}
