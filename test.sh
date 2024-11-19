#!/bin/bash
set -euo pipefail

podman pull ghcr.io/doridian/pdns-static/pdns-static:latest
podman build --target=builder -t pdns-builder .
podman run --rm -it pdns-builder
#podman build -t pdns-static .
#podman run --rm -it pdns-static
