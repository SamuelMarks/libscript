# Future Roadmap

This document covers the long-term technical vision and planned architectural enhancements for the LibScript framework.

## Extended OS Support

The framework currently supports Windows, Linux, FreeBSD, and macOS. Future development will focus on adding robust, native execution and package generation capabilities for OpenBSD and Illumos.

## Execution Optimizations

We plan to refine the dependency resolution engine to support concurrent execution of the component graph (DAG). This will reduce provisioning times for complex stacks on native hardware.

## Generator Enhancements

The `package_as docker` engine is under continuous optimization to improve the structural quality of the generated Dockerfiles. Upcoming improvements include deeper support for multi-stage builds and more precise layer caching directives.

## Integration Strategies

Future work will expand the ecosystem of plugins and integrations for existing configuration management tools, allowing DevOps teams to delegate cross-platform package resolution entirely to the LibScript engine.
