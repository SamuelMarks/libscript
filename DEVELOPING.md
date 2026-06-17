# Developing LibScript

LibScript is a decentralized framework for cross-platform software provisioning. Developing a new
component leverages the "Every-Thing-is-a-Package-Manager" architecture, allowing your tool to
become a first-class citizen in the global PaaS orchestration layer.

## The Decentralized Component Model

When you add a component to LibScript, you aren't just writing a setup script; you are creating an
autonomous manager. Components are located within the `_lib` directory under relevant categories
(e.g., `_lib/toolchains/my_tool`).

To create a new component:

1. **Define the Manager Directory**: Place it in the appropriate `_lib` subfolder.
2. **Implement `vars.schema.json`**: Define the tool's dependencies (with version constraints),
   required environment variables, and metadata (ports, volumes, etc.).
3. **Write Platform-Specific CLIs**: Provide `cli.sh` (POSIX) and `cli.cmd` (Windows) as entry
   points for the global router.
4. **Implement Setup Logic**: Create `setup.sh` and `setup.ps1` to handle the actual installation
   and configuration.

## Automatic Integration & Benefits

By adhering to this decentralized model, your component automatically inherits:

- **Global Dependency Resolution:** It can be included in `libscript.json` stacks and resolved by
  the versioning engine.
- **Artifact Generation:** It can be automatically compiled into Dockerfiles, MSI installers,
  DEB/RPM packages, and more.
- **Multicloud Deployment:** It can be bootstrapped onto AWS, Azure, or GCP nodes via the unified
  `provision` command.

## Developing Stacks & Cloud Primitives

If you are developing complex workflows (like AI Inference or multicloud primitives) rather than
individual tools:

- **Cloud Providers:** Place APIs for cloud management inside `_lib/cloud-providers/<provider>/`.
- **Pre-configured Stacks:** Combine tools (like Python, vLLM, and GCS Fuse) into a deployment
  workflow inside `stacks/ai-serving/` or `stacks/ml-training/`. Stack setups usually invoke
  multiple `_lib` component setups sequentially and provide a `deploy.sh` script to orchestrate the
  workload.

### Manifest Extensions (`libscript.json`)

When building stacks, your component definitions can interact with high-level infrastructure
concepts. You can define an `infrastructure` block to specify native VM sizing (e.g., `Standard_B2s`
or `t3.medium`), and an `ingress` block which the `netctl` engine will automatically map to web
servers like Nginx or Caddy.
