#!/bin/sh
set -e

# Fetch secrets from AWS
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$AWS_SECRET_NAME" \
  --region "$AWS_DEFAULT_REGION" \
  --query SecretString \
  --output text)

DB_USER=$(echo $SECRET_JSON | jq -r .DB_USER)
DB_PASSWORD=$(echo $SECRET_JSON | jq -r .DB_PASSWORD)
DB_NAME=$(echo $SECRET_JSON | jq -r .DB_NAME)

# Export for Postgres startup
export POSTGRES_USER=$DB_USER
export POSTGRES_PASSWORD=$DB_PASSWORD
export POSTGRES_DB=$DB_NAME

# Hand off to official Postgres entrypoint
exec docker-entrypoint.sh postgres

