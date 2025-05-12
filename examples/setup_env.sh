#!/bin/bash

# Script to configure .env file and run docker-compose

ENV_FILE=".env"
RECONFIGURE=false
UPGRADE=false
AWS_ACCOUNT_ID="891377372776" # Extracted from docker-compose.yml image paths

# --- Helper Functions ---

# Function to generate a random string (16 bytes, hex encoded)
generate_random_string() {
  if command -v openssl &> /dev/null; then
    openssl rand -hex 16
  else
    echo "WARNING: openssl not found. Using a less secure random string generator." >&2
    date +%s%N | sha256sum | base64 | head -c 32
  fi
}

# Function to prompt for a variable
# Usage: prompt_variable VAR_NAME "Prompt message" "default_value_if_empty" [is_secret]
prompt_variable() {
  local var_name="$1"
  local prompt_message="$2"
  local default_value_arg="$3"
  local is_secret="${4:-false}"
  local current_value
  local input_value
  local effective_default

  eval current_value="\$$var_name" # Get current value of the variable (if loaded from .env)

  if [ -n "$current_value" ]; then
    effective_default="$current_value"
  else
    effective_default="$default_value_arg"
  fi

  local prompt_display_default
  if [ "$is_secret" == "true" ]; then
    if [ -n "$effective_default" ]; then
      prompt_display_default="current value (hidden)"
    else
      prompt_display_default="empty / optional"
    fi
    read -sp "$prompt_message [$prompt_display_default]: " input_value
    echo # Newline after secret input
  else
    prompt_display_default="$effective_default"
    read -p "$prompt_message [$prompt_display_default]: " input_value
  fi

  if [ -z "$input_value" ]; then
    # User pressed Enter, use effective_default (which could be empty if no default_value_arg and no current_value)
    eval $var_name=\'"$effective_default"\'
  else
    eval $var_name=\'"$input_value"\'
  fi
}

# Load existing .env file if not reconfiguring
load_env() {
  if [ -f "$ENV_FILE" ] && [ "$RECONFIGURE" == "false" ]; then
    echo "Loading existing configuration from $ENV_FILE..."
    set -o allexport
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +o allexport
    echo "Done loading $ENV_FILE."
  elif [ "$RECONFIGURE" == "true" ]; then
    echo "Reconfiguring: Previous .env values will be shown as defaults if available."
    if [ -f "$ENV_FILE" ]; then
        # Load them so they appear as defaults, but we will overwrite the file.
        set -o allexport
        # shellcheck source=/dev/null
        source "$ENV_FILE"
        set +o allexport
    fi
  else
    echo "No $ENV_FILE found or reconfiguration not requested. Starting fresh configuration."
  fi
}

# Save all relevant variables to .env file
save_env() {
  echo "Saving configuration to $ENV_FILE..."
  >"$ENV_FILE" # Clear the file or create it

  local vars_to_save=(
    AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION NEXT_PUBLIC_AWS_BUCKET_NAME
    OPENAI_API_KEY
    AZURE_API_KEY AZURE_ENDPOINT AZURE_API_VERSION AZURE_DEPLOYMENT_NAME API_TYPE
    DB_MONGO_USER DB_MONGO_PASSWORD DB_MONGO_DATABASE DB_MONGO_COUNSEL_DB
    DB_MONGO_DOCGEN DB_MONGO_LIMIT DB_MONGO_CHATBOT
    SESSION_SECRET
    OIDC_BASE_URL OIDC_ISSUER OIDC_CLIENT_ID OIDC_ADMIN
    NEXT_PUBLIC_BRAND_IMG NEXT_PUBLIC_TITLE NEXT_PUBLIC_CONTACT NEXT_PUBLIC_HIDE_COPYRIGHT
    STRIPE_WEBHOOK_SECRET
  )

  for var_name in "${vars_to_save[@]}"; do
    # Get the value of the variable dynamically
    local value
    eval value="\$$var_name"
    # Only save if the variable is set (even if to an empty string, user might want that)
    # Docker-compose treats unset and empty differently. For .env, better to write `VAR=` if empty.
    if eval "[ -n \"\$$var_name\" ] || [ -z \"\$$var_name\" ]"; then # Check if var is set (can be empty)
        echo "$var_name=\"$value\"" >> "$ENV_FILE"
    fi
  done
  chmod 600 "$ENV_FILE" # Set permissions for the .env file
  echo "Configuration saved to $ENV_FILE."
}

# --- Main Script Logic ---

# Parse arguments
if [[ " $* " == *" --reconfigure "* ]]; then
  RECONFIGURE=true
fi

if [[ " $* " == *" --upgrade "* ]]; then
  UPGRADE=true
fi

load_env

echo ""
echo "---------------------------------------------------------------------"
echo "Welcome to the application configurator."
echo "Please provide the following details. Press Enter to accept the"
echo "current value (shown in brackets) or to leave an optional field empty."
echo "---------------------------------------------------------------------"
echo ""

# General API Configuration (moved to top)
echo "--- General API Configuration ---"
prompt_variable API_TYPE "Enter API Type (OPENAI or AZURE)" "${API_TYPE:-OPENAI}"

# AWS Configuration (always needed for ECR)
echo "--- AWS Configuration ---"
prompt_variable AWS_REGION "Enter AWS Region (e.g., us-east-1)" "${AWS_REGION:-us-east-1}"
prompt_variable AWS_ACCESS_KEY_ID "Enter AWS Access Key ID (optional)" "${AWS_ACCESS_KEY_ID}"
prompt_variable AWS_SECRET_ACCESS_KEY "Enter AWS Secret Access Key (optional)" "${AWS_SECRET_ACCESS_KEY}" true
prompt_variable NEXT_PUBLIC_AWS_BUCKET_NAME "Enter AWS S3 Bucket Name for frontend (optional)" "${NEXT_PUBLIC_AWS_BUCKET_NAME}"
echo ""

# OpenAI Configuration (only if API_TYPE is OPENAI)
if [ "$API_TYPE" = "OPENAI" ]; then
    echo "--- OpenAI Configuration ---"
    prompt_variable OPENAI_API_KEY "Enter OpenAI API Key" "${OPENAI_API_KEY}" true
    echo ""
fi

# Azure Configuration (only if API_TYPE is AZURE)
if [ "$API_TYPE" = "AZURE" ]; then
    echo "--- Azure Configuration ---"
    prompt_variable AZURE_API_KEY "Enter Azure API Key" "${AZURE_API_KEY}" true
    prompt_variable AZURE_ENDPOINT "Enter Azure Endpoint (e.g., https://your-resource.openai.azure.com/)" "${AZURE_ENDPOINT}"
    prompt_variable AZURE_API_VERSION "Enter Azure API Version (e.g., 2023-07-01-preview)" "${AZURE_API_VERSION}"
    prompt_variable AZURE_DEPLOYMENT_NAME "Enter Azure Deployment Name (for chat models)" "${AZURE_DEPLOYMENT_NAME}"
    echo ""
fi

# MongoDB Configuration
echo "--- MongoDB Configuration ---"
prompt_variable DB_MONGO_USER "Enter MongoDB Username" "${DB_MONGO_USER:-admin}"

# Special handling for DB_MONGO_PASSWORD (auto-generation)
echo "MongoDB Password:"
if [ -n "$DB_MONGO_PASSWORD" ]; then
  read -sp "Current MongoDB Password is set. Press Enter to keep, or type new password: " input_mongo_password
else
  read -sp "Enter MongoDB Password (leave blank to auto-generate): " input_mongo_password
fi
echo
if [ -n "$input_mongo_password" ]; then
  DB_MONGO_PASSWORD="$input_mongo_password"
elif [ -z "$DB_MONGO_PASSWORD" ]; then # Only generate if it was initially empty and user also left blank
  echo "Generating random MongoDB password..."
  DB_MONGO_PASSWORD=$(generate_random_string)
  echo "Generated MongoDB Password: $DB_MONGO_PASSWORD (will be saved to .env)"
fi

prompt_variable DB_MONGO_DATABASE "Enter main MongoDB Database Name" "${DB_MONGO_DATABASE:-app_db}"
prompt_variable DB_MONGO_COUNSEL_DB "Enter MongoDB Counsel DB Name" "${DB_MONGO_COUNSEL_DB:-counselDb}"
prompt_variable DB_MONGO_DOCGEN "Enter MongoDB DocGen DB Name" "${DB_MONGO_DOCGEN:-docgenDb}"
prompt_variable DB_MONGO_LIMIT "Enter MongoDB Query Result Limit" "${DB_MONGO_LIMIT:-1000}"
prompt_variable DB_MONGO_CHATBOT "Enter MongoDB Chatbot DB Name" "${DB_MONGO_CHATBOT:-chatbotDb}"
echo ""

# Session Secret
echo "--- Session Secret Configuration ---"
# Special handling for SESSION_SECRET (auto-generation)
echo "Session Secret:"
if [ -n "$SESSION_SECRET" ]; then
  read -sp "Current Session Secret is set. Press Enter to keep, or type new secret: " input_session_secret
else
  read -sp "Enter Session Secret (leave blank to auto-generate): " input_session_secret
fi
echo
if [ -n "$input_session_secret" ]; then
  SESSION_SECRET="$input_session_secret"
elif [ -z "$SESSION_SECRET" ]; then # Only generate if it was initially empty and user also left blank
  echo "Generating random Session Secret..."
  SESSION_SECRET=$(generate_random_string)
  echo "Generated Session Secret. (will be saved to .env)"
fi
echo ""

# OIDC Configuration
echo "--- OIDC Configuration (optional) ---"
prompt_variable OIDC_BASE_URL "Enter OIDC Base URL (e.g., https://your.okta.com)" "${OIDC_BASE_URL}"
prompt_variable OIDC_ISSUER "Enter OIDC Issuer (e.g., https://your.okta.com/oauth2/default)" "${OIDC_ISSUER}"
prompt_variable OIDC_CLIENT_ID "Enter OIDC Client ID" "${OIDC_CLIENT_ID}"
prompt_variable OIDC_ADMIN "Enter OIDC Admin role/group name" "${OIDC_ADMIN}"
echo ""

# Frontend Customization
echo "--- Frontend Customization (optional) ---"
prompt_variable NEXT_PUBLIC_BRAND_IMG "Enter URL for custom brand image" "${NEXT_PUBLIC_BRAND_IMG}"
prompt_variable NEXT_PUBLIC_TITLE "Enter custom title for the application" "${NEXT_PUBLIC_TITLE:-Talking Tree}"
prompt_variable NEXT_PUBLIC_CONTACT "Enter contact email/info for support page" "${NEXT_PUBLIC_CONTACT}"
prompt_variable NEXT_PUBLIC_HIDE_COPYRIGHT "Hide copyright footer? (true/false)" "${NEXT_PUBLIC_HIDE_COPYRIGHT:-false}"
echo ""

# Stripe Configuration
echo "--- Stripe Configuration (optional) ---"
prompt_variable STRIPE_WEBHOOK_SECRET "Enter Stripe Webhook Secret" "${STRIPE_WEBHOOK_SECRET}" true
echo ""

# Save configuration to .env file
save_env
echo ""

# AWS ECR Login
echo "--- AWS ECR Docker Login ---"
if [ -n "$AWS_REGION" ]; then
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI is not installed. Skipping ECR login."
        echo "Please install AWS CLI if your images are in ECR and require authentication: https://aws.amazon.com/cli/"
    else
        echo "Attempting to login to AWS ECR for account $AWS_ACCOUNT_ID in region $AWS_REGION..."
        # AWS CLI will use AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN from env if set,
        # otherwise its configured credentials/profile.
        # The load_env function already exported these if they were in .env or set by prompts.
        if aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"; then
            echo "AWS ECR login successful for $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com."
        else
            echo "AWS ECR login failed. Potential issues:" >&2
            echo "- Incorrect AWS Region, Access Key ID, or Secret Access Key." >&2
            echo "- AWS CLI not configured correctly (if keys were not provided to this script)." >&2
            echo "- Insufficient IAM permissions for ECR." >&2
            echo "You may need to configure AWS CLI or ensure the provided credentials are correct." >&2
        fi
    fi
else
  echo "AWS_REGION not set. Skipping ECR login."
  echo "If your images are in ECR and require authentication, 'docker-compose pull' might fail."
fi
echo ""

# Run Docker Compose
echo "--- Docker Compose ---"
if ! command -v docker-compose &> /dev/null; then
    echo "docker-compose command not found. Please install it." >&2
    echo "See: https://docs.docker.com/compose/install/" >&2
    exit 1
fi

if [ "$UPGRADE" = true ]; then
    echo "Upgrading Docker containers..."
    
    # Ensure ECR login if AWS region is set
    if [ -n "$AWS_REGION" ]; then
        if ! command -v aws &> /dev/null; then
            echo "AWS CLI is not installed. Skipping ECR login."
            echo "Please install AWS CLI if your images are in ECR and require authentication: https://aws.amazon.com/cli/"
        else
            echo "Authenticating with AWS ECR..."
            if aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"; then
                echo "AWS ECR login successful."
            else
                echo "AWS ECR login failed. Continuing with upgrade anyway..." >&2
            fi
        fi
    fi
    
    echo "Pulling latest images..."
    docker-compose pull
    
    echo "Stopping existing containers..."
    docker-compose down
    
    echo "Starting containers with latest images..."
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "---------------------------------------------------------------------"
        echo "Containers successfully upgraded and restarted!"
        echo "You can view logs using: docker-compose logs -f"
        echo "---------------------------------------------------------------------"
    else
        echo ""
        echo "---------------------------------------------------------------------"
        echo "ERROR: Container upgrade failed." >&2
        echo "Check the output above for errors." >&2
        echo "---------------------------------------------------------------------"
        exit 1
    fi
else
    echo "Starting Docker Compose services in detached mode (docker-compose up -d)..."
    echo "This may take a while if images need to be pulled."
    docker-compose up -d

    if [ $? -eq 0 ]; then
        echo ""
        echo "---------------------------------------------------------------------"
        echo "Application services started successfully!"
        echo "You can view logs using: docker-compose logs -f"
        echo "To stop services: docker-compose down"
        echo "To reconfigure, run this script with the --reconfigure flag: ./setup_env.sh --reconfigure"
        echo "To upgrade containers, run this script with the --upgrade flag: ./setup_env.sh --upgrade"
        echo "---------------------------------------------------------------------"
    else
        echo ""
        echo "---------------------------------------------------------------------"
        echo "ERROR: docker-compose up -d failed." >&2
        echo "Check the output above for errors. You might want to run:" >&2
        echo "  docker-compose config   (to validate your docker-compose.yml and .env)" >&2
        echo "  docker-compose pull     (to see if image pulling is the issue)" >&2
        echo "  docker-compose up       (without -d, to see logs in foreground)" >&2
        echo "---------------------------------------------------------------------"
        exit 1
    fi
fi

exit 0 