# Overview
This stage is a placeholder for any number of precursor stages which might exist in a production system. These stages would be responsible for configuring the system and passing down information about the system to subsequent stages. 

In this case, this stage creates S3 buckets for storing terraform state to be used by the `tf-deploy` stage, provisions a least-privilege role to be used by the `tf-deploy` stage, and writes a providers file for that stage specifying the 