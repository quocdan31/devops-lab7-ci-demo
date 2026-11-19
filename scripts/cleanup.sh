#!/bin/bash
# scripts/cleanup.sh - Don dep containers Lab 7

echo "Dang dung va go bo cac containers Lab 7..."
docker compose down

echo "Trang thai containers sau khi don dep:"
docker ps -a --filter "name=lab7-"
