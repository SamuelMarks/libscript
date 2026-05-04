# Amazon Web Services (AWS)

This module configures the `aws` cloud provider capabilities within LibScript. It leverages the AWS CLI and associated tools to provide provisioning and configuration targets for Amazon Web Services.

## Purpose & Current State
- Provides runtime context and authentication pathways for AWS targets.
- Serves as the foundation for multi-cloud deployments bridging to EC2, EKS, and S3 resources.

## Usage
Used internally by the `libscript deploy` and `libscript teardown` systems when AWS is the target provider.
