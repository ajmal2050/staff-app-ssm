#!/bin/sh
set -e

# Fetch secrets from AWS Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$AWS_SECRET_NAME" \
  --region "$AWS_DEFAULT_REGION" \
  --query SecretString \
  --output text)

# Parse values using jq
export DB_USER=$(echo $SECRET_JSON | jq -r .DB_USER)
export DB_PASSWORD=$(echo $SECRET_JSON | jq -r .DB_PASSWORD)
export DB_NAME=$(echo $SECRET_JSON | jq -r .DB_NAME)
export REDIS_HOST=$(echo $SECRET_JSON | jq -r .REDIS_HOST)

echo "✅ Secrets fetched from AWS Secrets Manager"
echo "DB_USER=$DB_USER"
echo "DB_NAME=$DB_NAME"
echo "REDIS_HOST=$REDIS_HOST"

# Start Node.js backend
exec node server.js

