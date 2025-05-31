# Overview
AWS Terraform playground - a simple demo of a web server deployment and configuration using (mostly) standard tooling and approaches. Some treatment of FedRAMP and other compliance considerations.

This demo explores the use of terraform to provision the following resources:

- A VPC with a public and private subnet (private subnet is unused, but included as segregation via subnetting is a core FedRAMP requirement- if there were servers other than the web server in this example they would reside there)
- Dedicated [AWS Customer Managed Keys](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html) for encrypting EBS volumes and S3 buckets. Use of CMKs instead of default encryption is generally a compliance requirement, and use of dedicated CMKs for different resource types and use cases is best practice.
- A single Amazon Linux 2023 web server with a public IP. This web server is fronted by an application load balancer so _could_ be deployed in a private subnet with a NAT gateway or other egress traffic solution, but that is outside of scope for this example.
- An S3 bucket which allows least-privilege (list and read) access by the web server instance profile.

```mermaid
architecture-beta
    group api(logos:aws-lambda)[API]

    service db(logos:aws-aurora)[Database] in api
    service disk1(logos:aws-glacier)[Storage] in api
    service disk2(logos:aws-s3)[Storage] in api
    service server(logos:aws-ec2)[Server] in api

    db:L -- R:server
    disk1:T -- B:server
    disk2:T -- B:db