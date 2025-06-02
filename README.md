# Overview
AWS Terraform playground - a simple demo of a web server deployment and configuration using (mostly) standard tooling and approaches. Some treatment of FedRAMP and other compliance considerations.

This demo explores the use of terraform to provision the following resources:

- A VPC with a public and private subnet (private subnet is unused, but included as segregation via subnetting is a core FedRAMP requirement- if there were servers other than the web server in this example they would reside there)
- Dedicated [AWS Customer Managed Keys](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html) for encrypting EBS volumes and S3 buckets. Use of CMKs instead of default encryption is generally a compliance requirement, and use of dedicated CMKs for different resource types and use cases is best practice.
- A single Amazon Linux 2023 web server with a public IP. This web server is fronted by an application load balancer so _could_ be deployed in a private subnet with a NAT gateway or other egress traffic solution, but that is outside of scope for this example.
- An S3 bucket which allows least-privilege (list and read) access by the web server instance role.

TODO: Architecture diagram svg

# What this demo does not address
- Logging and retention. Programs such as FedRAMP have [extensive requirements around log collection and retention](https://www.whitehouse.gov/wp-content/uploads/2021/08/M-21-31-Improving-the-Federal-Governments-Investigative-and-Remediation-Capabilities-Related-to-Cybersecurity-Incidents.pdf). As this is meant to be essentially an ephemeral demo, logging to destinations such as [CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html) or S3 is not addressed. 
- [AWS FIPS compliance](https://aws.amazon.com/compliance/fips/). The AWS CLI can be forced to use FIPS endpoints by setting `export AWS_USE_FIPS_ENDPOINT=true`, but as this adds some complexity we'll bypass it for the purposes of this demo as it will cause operations such as listing S3 buckets to fail due to the fact that the FIPS endpoints only support virtual hosted style addressing. Know only that this setting can matter a great deal when designing compliant solutions.


# Prerequisites
1. An AWS account with a sufficiently privileged user. 
2. [AWS CLI](https://aws.amazon.com/cli/) installed
3. [Terraform](https://developer.hashicorp.com/terraform) installed

# Setup
Most users of this demo will likely be deploying into a personal account, so solutions such as [IAM Identity Center short term credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html) may be out of scope.

In general, the use of long term credentials should be avoided, and this becomes more important the greater the privileges associated with those credentials are. If short term credentials are available, use them. If they are not trivially available and if long term credentials (IAM user access key and secret key) are used, ***ensure to disable and/or delete the access key and secret key upon completion***.

This guide eschews the use of a config file containing secrets, opting to [use environment variables instead](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html). Included in this is a [variable to force the use of FIPS endpoints where available](https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-endpoints.html#endpoints-fips).


1. Export the AWS access key and secret key ID as environment variables:
```bash
export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key
```
