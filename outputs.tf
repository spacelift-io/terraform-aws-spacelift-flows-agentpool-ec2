
output "autoscaling_group_name" {
  description = "Name of the agent pool autoscaling group"
  value       = aws_autoscaling_group.agent_pool.name
}

output "autoscaling_group_arn" {
  description = "ARN of the agent pool autoscaling group"
  value       = aws_autoscaling_group.agent_pool.arn
}