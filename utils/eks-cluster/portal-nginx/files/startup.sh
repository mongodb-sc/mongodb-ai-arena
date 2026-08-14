#!/bin/bash

# Exit on any error
set -e

#########################################
# Read Configuration from ConfigMap
#########################################
echo "Reading scenario configuration..."
if [ ! -f "/etc/scenario-config/scenario-config.json" ]; then
    echo "ERROR: scenario-config.json not found in ConfigMap mount"
    exit 1
fi

# Parse JSON configuration using jq (install if not available)
# Install required packages for Alpine Linux
echo "Installing required packages..."
if command -v apk >/dev/null 2>&1; then
    apk update
    apk add jq git
elif command -v apt-get >/dev/null 2>&1; then
    apt-get update
    apt-get install -y jq git
else
    echo "ERROR: No supported package manager found (apk or apt-get)"
    exit 1
fi

# Extract configuration values
SCENARIO=$(jq -r '.scenario // "guided"' /etc/scenario-config/scenario-config.json)
AWS_ROUTE53_RECORD_NAME=$(jq -r '.aws_route53_record_name // "localhost"' /etc/scenario-config/scenario-config.json)
REPOSITORY=$(jq -r '.repository // "https://github.com/mongodb-sc/mongodb-ai-arena.git"' /etc/scenario-config/scenario-config.json)
BRANCH=$(jq -r '.branch // "main"' /etc/scenario-config/scenario-config.json)
NAVIGATION_BASE=$(jq -r '.instructions.base // "navigation.yml"' /etc/scenario-config/scenario-config.json)

#########################################
# Clone and Prepare Repository
#########################################
echo "Cloning repository..."
cd /tmp
git clone -b $BRANCH $REPOSITORY

# Extract repository name from URL (removes .git suffix if present)
REPO_NAME=$(basename "$REPOSITORY" .git)
echo "Repository name: $REPO_NAME"

# Set working directory to the Flask app location
cd /tmp/$REPO_NAME/utils/eks-cluster/mongodb-arena-portal/frontend

# Build the frontend app
echo "Installing dependencies and building frontend..."
npm install

echo "Building frontend application..."
npm run build

# Check if build output directory exists
if [ ! -d "out" ]; then
    echo "ERROR: Build output directory 'out' not found after npm run build"
    echo "Available directories:"
    ls -la
    exit 1
fi

# Check if build output directory has files
if [ ! "$(ls -A out)" ]; then
    echo "ERROR: Build output directory 'out' is empty"
    exit 1
fi

# Move build output to nginx html directory
echo "Moving build output to /usr/share/nginx/html/portal..."
mkdir -p /usr/share/nginx/html/portal
cp -r out/* /usr/share/nginx/html/portal/

echo "Build output successfully copied to nginx directory"
