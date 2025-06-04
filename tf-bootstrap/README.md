# Overview
This stage is a placeholder for any number of precursor stages which might exist in a production system. These stages would be responsible for configuring the system and passing down information about the system to subsequent stages. 

In this demo, the "bootstrap" stage creates an S3 bucket for storing terraform state to be used by the `tf-deploy` stage, provisions a least-privilege role to be used by the `tf-deploy` stage, and writes a providers file for that stage specifying the bucket as the backend.

This configuration is relevant to requirements such as FedRAMP where control needs to be maintained over the terraform state- storing the state outside of the "system boundary" heightens the risk of unintentional exposure and would generally be considered some form of external system interconnection.

In addition to defining the providers file for the subsequent stage, the bootstrap stage passes down information as `tf-boostrap.auto.tfvars.json` - this pattern can be extended to establish a form of contract between stages where foundational stages selectively pass information about to later stages.

In this demo, the files are written directly to the filesystem on the deployment machine, but in a production deployment these would typically be staged in an object store or otherwise placed in a location where they can be reliably fetched to allow collaboration by multiple users and decoupling of the stages.