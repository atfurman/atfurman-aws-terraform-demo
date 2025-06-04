# Overview
This stage takes environment info from the [tf-bootstrap](../tf-bootstrap/README.md) stage:

- Dynamically generated `providers.tf`
- System information passed down in `tf-bootstrap.auto.tfvars.json`

It deploys the "core" resources for the demo. As with bootstrap, resource types are split into multiple terraform files for easier review and management.