output "stack_id" {
  description = "The unique identifier for the stack."
  value       = aws_cloudformation_stack.chatbot_slack_configuration.id
}

output "configuration_arn" {
  description = "The ARN of the Chatbot Slack configuration"
  value       = aws_cloudformation_stack.chatbot_slack_configuration.outputs.ConfigurationArn
}
