#!/bin/bash
docker buildx build --platform linux/amd64 -t vkobinski/rinha-zig:latest .
