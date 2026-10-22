output "vpc_name" {
    value = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
    value = aws_vpc.vpc.cidr_block
}

output "load_balancer_dns_name" {
    value = aws_lb.instance_alb.dns_name
}

output "instance_name" {
    value = var.instance_name
}

output "instance_type" {
    value = aws_instance.apache_instance1.instance_type
}