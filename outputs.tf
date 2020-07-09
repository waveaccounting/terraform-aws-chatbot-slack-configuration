output "configuration_arn" {
  description = "The ARN of the Chatbot Slack configuration"
  value       = aws_cloudformation_stack.chatbot_slack_configuration.outputs.ConfigurationArn
}
