data "local_file" "cloudformation_template" {
  filename = "${path.module}/cloudformation.yml"
}

resource "aws_cloudformation_stack" "chatbot_slack_configuration" {
  name = "chatbot-slack-configuration-${var.configuration_name}"

  template_body = data.local_file.cloudformation_template.content

  parameters = {
    ConfigurationNameParameter  = var.configuration_name
    GuardrailPolicyArnParameter = var.guardrail_policy_arn
    IamRoleArnParameter         = var.iam_role_arn
    LoggingLevelParameter       = var.logging_level
    SlackChannelIdParameter     = var.slack_channel_id
    SlackWorkspaceIdParameter   = var.slack_workspace_id
    SnsTopicArnsParameter       = join(",", var.sns_topic_arns)
    UserRoleRequiredParameter   = var.user_role_required
  }

  tags = var.tags
}
