AWS EC2 Apache Web Server

This repository contains the infrastructure and container configuration for deploying an apache web server onto AWS EC2 within a private subnet. The application is secured and accelerated globally behind an AWS Application Load Balancer (ALB).

🏗️ Architecture Overview

[ Internet ] ➔[ Public Subnet: ALB ] │ ▼ (VPC Internal Routing on Port 80) [ Private Subnet: EC2 instance ] 

Application Load Balancer (ALB): Sits in public subnets to receive proxied traffic from the internet and routes it down to the private subnet targets.

AWS EC2 Instance: Runs the apache web server 3hich lives inside a private subnet and have no public IP addresses.
Target Group Config: Configured with target_type = "instance" routing directly to the dynamic private IPs assigned to the apache server.

Virtual Private Cloud (VPC): A custom VPC is created, it contains all the networking resources for both private and public connections. This is where all the SGs, route tables, internet-gateway, NAT-gateway, all the subnets and the 2 AZs are.


🛠️ Terraform Infrastructure Map

The infrastructure is written entirely in Terraform. Below are the key configuration alignment specifications used to stitch the network and security elements together.

1. Port Integration

To avoid standard 502 Bad Gateway loops, ports must be consistently mapped as integers across the entire pipeline:

Apache web server: by default runs on port 80 unless configured otherwise.
ALB Target Group (port): Port 80

2. Security Group Blueprint

Traffic is tightly restricted so that the web server accept requests exclusively from the load balancer.

ALB Security Group: Allows inbound HTTP/HTTPS from the internet IP ranges (0.0.0.0/0 during initial setup) and outbound traffic to the web server Security Group.
Web Server Security Group: Drops all outside incoming connections. It explicitly allows ingress only from the ALB Security Group ID on port 80:
ingress {
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_groups = [aws_security_group.alb_sg.id] # Locks down to ALB only
}
🚀 Troubleshooting and Health Checks

If tasks are cycling or flagging as Unhealthy, verify the Target Group status:

HTTP 404 Status: The load balancer is reaching the server, but server cannot find the specific health path. Ensure your aws_lb_target_group health check path is configured to match your active codebase (typically / if serving a standard root index).
HTTP 403 Status: server is running but cannot locate an index.html