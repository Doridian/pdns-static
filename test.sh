#!/bin/bash
set -euo pipefail

sudo docker build --target=builder -t pdns-builder .
sudo docker run --rm -it pdns-builder
