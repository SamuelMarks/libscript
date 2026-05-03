# GCP Cloud Provider Configuration

This module configures the `gcp` cloud provider capabilities within LibScript. It leverages the Google Cloud SDK (`gcloud`) to provide provisioning and configuration targets for Google Cloud Platform.

## Features
- Provides runtime context and authentication pathways for GCP targets.
- Serves as the foundation for multi-cloud deployments bridging to GCE, GKE, and Google Cloud Storage.

## Usage
Used internally by the `libscript deploy` and `libscript teardown` systems when GCP is the target provider.
