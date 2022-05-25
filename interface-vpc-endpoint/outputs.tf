output "instance_id" {
  value = aws_instance.instance.id
}

output "command" {
  value = format("Instance %s created, use aws ssm start-session --target %s --region us-east-1", aws_instance.instance.id, aws_instance.instance.id)
}