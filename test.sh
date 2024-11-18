#!/bin/bash
set -euo pipefail

podman build --target=builder -t pdns-builder .
podman run --rm -it pdns-builder
