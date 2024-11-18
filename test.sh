#!/bin/sh
sudo docker build --target=builder -t pdns-builder . && docker run --rm -it pdns-builder
