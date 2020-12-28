output "public-ip" {
  description = "Public IP address"
  value       = "${aws_eip.buildstack-eip.public_ip}"
}

output "public-hostname" {
  description = "Public hostname"
  value       = "${aws_eip.buildstack-eip.public_dns}"
}