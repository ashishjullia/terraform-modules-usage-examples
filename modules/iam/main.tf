resource "aws_iam_role" "iam_role" {
  count = var.create_role ? 1 : 0

  name                 = var.role_name
  assume_role_policy = jsonencode(var.role_assume_role_policy_data)
}

resource "aws_iam_role_policy_attachment" "custom" {
  count = var.create_role ? coalesce(var.number_of_custom_role_policy_arns, length(var.custom_role_policy_arns)) : 0

  role       = aws_iam_role.iam_role[0].name
  policy_arn = element(var.custom_role_policy_arns, count.index)
}


data "aws_iam_policy_document" "inline" {
  count = var.create_iam_role_inline_policy ? 1 : 0
  dynamic "statement" {
    for_each = var.inline_policy_statements

    content {
      actions       = try(statement.value.actions, null)
      not_actions   = try(statement.value.not_actions, null)
      effect        = try(statement.value.effect, null)
      resources     = try(statement.value.resources, null)
      not_resources = try(statement.value.not_resources, null)

      dynamic "principals" {
        for_each = try(statement.value.principals, [])

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = try(statement.value.not_principals, [])

        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = try(statement.value.conditions, [])

        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

resource "aws_iam_role_policy" "inline" {
  count = var.create_iam_role_inline_policy ? 1 : 0

  role        = aws_iam_role.iam_role[0].name
  policy      = data.aws_iam_policy_document.inline[0].json
}
