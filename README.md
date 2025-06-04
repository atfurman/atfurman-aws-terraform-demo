# Overview
This is a demo intended to explore in a relatively straightforward fashion a few of the approaches taken with production systems subject to FedRAMP and DoD requirements.

## What this demo addresses (and why)

This demo explores the use of terraform to deploy and configure an example environment. The following approaches are addressed:

- A decoupled approach, where terraform is split in to ordered "stages" to facilitate the use of least privilege for more common operations while "core" stages manage more sensitive or infrequently modified infrastructure and configurations
- An "in boundary" S3 terraform backend where the provider is [dynamically generated and passed to a subsequent stage](./tf-bootstrap/outputs.tf)
- A VPC with public and private subnets (private subnets are unused, but included as segregation via subnetting is a core FedRAMP requirement- if there were servers other than the web server(s) in this example they would reside in non-public subnets if possible)
- Dedicated [AWS Customer Managed Keys](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html) for encrypting EBS volumes and S3 buckets. Use of CMKs instead of default encryption is generally a compliance requirement, and use of dedicated CMKs for different resource types and use cases is best practice.
- A single Amazon Linux 2023 web server with a public IP. This web server is fronted by an application load balancer so _could_ be deployed in a private subnet with a NAT gateway or other egress traffic solution, but that is outside of scope for this example.
- An S3 bucket which allows access by the web server instance role.
- Use of SSM to store sensitive information in SecureString parameters (in this case the cert and key used by the ALB and nginx) for later use by other automation
- Use of SSM documents and associations to configure the demo web server.

![demo architecture](./demo-architecture.svg)

## What this demo does not address (and why)
- Logging and retention. Programs such as FedRAMP have [extensive requirements around log collection and retention](https://www.whitehouse.gov/wp-content/uploads/2021/08/M-21-31-Improving-the-Federal-Governments-Investigative-and-Remediation-Capabilities-Related-to-Cybersecurity-Incidents.pdf). As this is meant to be essentially an ephemeral demo, logging to destinations such as [CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html) or S3 is not addressed. 
- [AWS FIPS compliance](https://aws.amazon.com/compliance/fips/). The AWS CLI can be forced to use FIPS endpoints by setting `export AWS_USE_FIPS_ENDPOINT=true`, but as this adds some complexity we'll bypass it for the purposes of this demo as it will cause operations such as listing S3 buckets to fail due to the fact that the FIPS endpoints only support virtual hosted style addressing. Know only that this setting can matter a great deal when designing compliant solutions. Terraform functions without issue with the `use_fips_endpoint = true` option so that is set in providers.
- STIG/CIS hardening. This matters a great deal for servers and applications, but is not addressed at all in this demo. Generally if deploying into production, some form of hardening pipeline would be utilized and one would not be launching vanilla Amazon Linux to host workloads.

# Prerequisites
1. Linux or Mac deployment system. This was developed and tested on Ubuntu 24.04 running on WSL.
2. An AWS account with a sufficiently privileged principal to enable deployment of the [tf-bootstrap](./tf-bootstrap/README.md) stage.
3. [AWS CLI](https://aws.amazon.com/cli/) installed
4. [Terraform](https://developer.hashicorp.com/terraform) installed

# Setup
Most users of this demo will likely be deploying into a personal account, so solutions such as [IAM Identity Center short term credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html) may be out of scope.

In general, the use of long term credentials should be avoided, and this becomes more important the greater the privileges associated with those credentials are. If short term credentials are available, use them. If they are not trivially available and if long term credentials (IAM user access key and secret key) are used, ***ensure to disable and/or delete the access key and secret key upon completion***.

This guide eschews the use of a config file containing secrets, opting to [use environment variables instead](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html).

1. Export the AWS access key and secret key ID as environment variables:
```bash
export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key
```

## Deploy
1. Begin by applying the [tf-bootstrap](./tf-bootstrap/README.md) stage. 
2. Apply the [tf-deploy](./tf-deploy/README.md) stage once bootstrap has completed. These stages provision the core infrastructure. 
3. Once the tf deploy stage has completed, validate that the SSM `ServerConfiguration` association has successfully applied. Once this association has successfully applied and the page is accessible at the `alb_address`, run the [monitor script](./monitor/README.md). If desired, test the script by stopping nginx so that the monitor takes corrective action.

## Cleanup
- `terraform destroy` the stages in reverse order from deployment. Note that the `tf-bootstrap` stage will fail to destroy the `tf-state` bucket. This is intended as it prevents terraform state for the `tf-deploy` stage from being inadvertently destroyed. Delete all versions in the bucket before proceeding.
- Ensure to disable any long term credentials which were created to deploy this demo.

# Summary

## Challenges and areas for improvement
- Initially I intended to use Ansible over SSM, as this has been used to good effect in GCP when connecting to VMs using IAP. However, this was not as straightforward as expected, so I opted to use SSM documents and associations deployed using terraform in the interest of getting results quickly. Its not as clean and scalable a solution as originally intended, but it gets the job done well enough for demo purposes.
- The monitor takes a very simplistic approach to remedial action. If health checks fail, it stops and starts the VM. The solution could be improved considerably by having the monitor take specific actions depending on the type of failure. For instance, if the web server is not responding at all restart it, but if it is responding and serving "incorrect" content, run a ssm document to update the configuration, etc.

## How would a production deployment differ?
- Web servers would very likely not be deployed with public IPs. Networking would be considerably more complex and some form of traffic inspection would likely be implemented
- We would not be running an endpoint monitor locally. This would likely be accomplished by somme combination of health checks or serverless functions depending on the complexity of the checks
- The monitor was largely written by Claude Sonnet 4. Its fine as a toy, but would need substantial modification to become anything approaching "production ready" and we certainly would not want it operating with the permissions it does for this demo
- Some form of hardening pipeline would be implemented; we'd not be launching vanilla AL2023 to host workloads
- It is quite possible that the stage which deploys the servers would be operating within an established networking context, and would be deploying within subnets that are owned by upstream stages
- Least-privilege for deployment principals. This demo does _not_ take a least privilege approach to the `demo-tf-deploy"` role.
- Terraform state for the `tf-bootstrap` stage would be migrated to a non-local backend after apply. 