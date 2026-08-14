#!/bin/bash

# Exit immediately if any command fails
set -e
set -o pipefail

# Function to handle errors
handle_error() {
    local exit_code=$1
    local line_number=$2
    local command="$3"
    echo_with_timestamp "ERROR: Command '$command' failed with exit code $exit_code at line $line_number"
    echo_with_timestamp "FATAL: User operations script failed - pod should be restarted"
    exit $exit_code
}

# Set error trap
trap 'handle_error $? $LINENO "$BASH_COMMAND"' ERR

# Function to echo with timestamp for long operations
echo_with_timestamp() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message"
}

# Function to extract repository name from URL
get_repo_name() {
    local repo_url="$1"
    basename "$repo_url" .git
}

echo_with_timestamp "Reading enhanced scenario configuration"
# Check if the enhanced scenario config file exists and read it
if [ -f "/home/workspace/scenario-config/enhanced-scenario-config.json" ]; then
    echo_with_timestamp "Enhanced scenario config found, reading configuration..."
    
    # Read the JSON file and extract values using jq
    SCENARIO_CONFIG=$(cat /home/workspace/scenario-config/enhanced-scenario-config.json)

    echo_with_timestamp "Enhanced scenario configuration loaded successfully"
    
    # Extract values from enhanced scenario config
    URL=$(echo "$SCENARIO_CONFIG" | jq -r '.aws_route53_record_name // ""')
    ATLAS_SRV=$(echo "$SCENARIO_CONFIG" | jq -r '.atlas_standard_srv // ""')
    ATLAS_PWD=$(echo "$SCENARIO_CONFIG" | jq -r '.atlas_user_password // ""')
    BACKEND_TYPE=$(echo "$SCENARIO_CONFIG" | jq -r '.backend // ""')
    REPOSITORY=$(echo "$SCENARIO_CONFIG" | jq -r '.repository // "https://github.com/mongodb-sc/mongodb-ai-arena"')
    BRANCH=$(echo "$SCENARIO_CONFIG" | jq -r '.branch // "main"')
    FRONTEND_TYPE=$(echo "$SCENARIO_CONFIG" | jq -r '.frontend // ""')
    PRECONFIGURE_MDB_CONNECTION=$(echo "$SCENARIO_CONFIG" | jq -r '.vscode.preconfigure_mongodb_connection // false')
    AUTOSTART_MCP_SERVER=$(echo "$SCENARIO_CONFIG" | jq -r '.vscode.autostart_mcp_server // false')
    PRECONFIGURE_CLINE=$(echo "$SCENARIO_CONFIG" | jq -r '.cline.preconfigure // false')
    CLINE_BASE_URL=$(echo "$SCENARIO_CONFIG" | jq -r '.cline.base_url // ""')
    CLINE_API_KEY=$(echo "$SCENARIO_CONFIG" | jq -r '.cline.api_key // ""')
    CLINE_MODEL=$(echo "$SCENARIO_CONFIG" | jq -r '.cline.model // ""')
    # Add LLM proxy configuration variables
    # LLM_MODEL=$(echo "$SCENARIO_CONFIG" | jq -r '.llm.model // ""')
    # LLM_REGION=$(echo "$SCENARIO_CONFIG" | jq -r '.llm.region // ""')
    # LLM_PROXY_ENABLED=$(echo "$SCENARIO_CONFIG" | jq -r '.llm.proxy.enabled // false')
    # LLM_PROXY_TYPE=$(echo "$SCENARIO_CONFIG" | jq -r '.llm.proxy.type // ""')
    # LLM_PROXY_SERVICE=$(echo "$SCENARIO_CONFIG" | jq -r '.llm.proxy."service-name" // ""')
    # LLM_PROXY_PORT=$(echo "$SCENARIO_CONFIG" | jq -r '.llm.proxy.port // ""')
    # LLM_BEDROCK=$(echo "$SCENARIO_CONFIG" | jq -r '.llm.bedrock // false')

else
    echo_with_timestamp "Warning: Enhanced scenario config file not found at /home/workspace/scenario-config/enhanced-scenario-config.json"
    # Set defaults if config file not found
    REPOSITORY="https://github.com/mongodb-sc/mongodb-ai-arena"
    BRANCH="main"
    FRONTEND_TYPE="app"
    PRECONFIGURE_MDB_CONNECTION="false"
    AUTOSTART_MCP_SERVER="false"
    PRECONFIGURE_CLINE="false"
fi

# Extract repository name from URL
REPO_NAME=$(get_repo_name "$REPOSITORY")
REPO_PATH="/home/workspace/$REPO_NAME"

echo_with_timestamp "Repository: $REPOSITORY"
echo_with_timestamp "Repository folder: $REPO_NAME"

# Check if the repository exists and update or clone accordingly.
# On first start with a fresh PVC, seed from /opt/prebaked/ (baked into the image)
# to avoid a full clone — then pull only the delta.
PREBAKED_PATH="/opt/prebaked/$REPO_NAME"

# Use a writable gitconfig path — linuxserver sets $HOME=/config which may not be
# writable when the init container runs as abc before s6-overlay has set permissions.
export GIT_CONFIG_GLOBAL="/home/workspace/.gitconfig"

if [ -d "$REPO_PATH/.git" ]; then
    echo_with_timestamp "Repository exists on workspace. Pulling latest changes..."
    # Seed .cline/skills into the OpenVSCode workspace folder (always server/, set by portal ?folder= URL)
    SKILLS_DEST="$REPO_PATH/server/.cline/skills"
    if [ -d "/opt/prebaked/.cline/skills" ] && { [ ! -d "$SKILLS_DEST" ] || [ -z "$(ls -A "$SKILLS_DEST" 2>/dev/null)" ]; }; then
        mkdir -p "$SKILLS_DEST"
        cp -r /opt/prebaked/.cline/skills/. "$SKILLS_DEST/"
        echo_with_timestamp "Seeded .cline/skills into $SKILLS_DEST from pre-baked image cache"
    fi
    git config --global --add safe.directory "$REPO_PATH"
    cd "$REPO_PATH"

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo_with_timestamp "FATAL: Directory exists but is not a valid git repository: $REPO_PATH"
        exit 1
    fi

    if ! git pull; then
        echo_with_timestamp "FATAL: Failed to pull latest changes from repository"
        exit 1
    fi

    # Restore node_modules symlinks if missing (pod restart after Option A seeding)
    # Only restore if checksum still matches — otherwise npm install will recreate them
    for dir in server app; do
        if [ ! -e "$REPO_PATH/$dir/node_modules" ] && [ -d "$PREBAKED_PATH/$dir/node_modules" ]; then
            STORED_HASH=$(cat "$REPO_PATH/$dir/.npm-checksum" 2>/dev/null || echo "")
            CURRENT_HASH=$(md5sum "$REPO_PATH/$dir/package.json" 2>/dev/null | awk '{print $1}' || echo "")
            if [ -n "$STORED_HASH" ] && [ "$CURRENT_HASH" = "$STORED_HASH" ]; then
                ln -s "$PREBAKED_PATH/$dir/node_modules" "$REPO_PATH/$dir/node_modules"
                echo_with_timestamp "Restored $dir/node_modules symlink from pre-baked cache"
            fi
        fi
    done
elif [ -d "$PREBAKED_PATH/.git" ]; then
    echo_with_timestamp "Fresh workspace detected. Seeding from pre-baked image cache (excluding node_modules)..."
    mkdir -p "$REPO_PATH"
    # Copy everything except node_modules to avoid writing thousands of small files to EFS
    tar -C "$PREBAKED_PATH" \
        --exclude='./server/node_modules' \
        --exclude='./app/node_modules' \
        -cf - . | tar -C "$REPO_PATH" -xf -
    git config --global --add safe.directory "$REPO_PATH" 2>/dev/null || true
    cd "$REPO_PATH"
    echo_with_timestamp "Pulling latest changes on top of pre-baked clone..."
    if ! git pull; then
        echo_with_timestamp "WARNING: git pull failed, continuing with pre-baked version"
    fi
    # Symlink node_modules from image layer — avoids EFS write overhead entirely
    for dir in server app; do
        if [ -d "$PREBAKED_PATH/$dir/node_modules" ]; then
            ln -s "$PREBAKED_PATH/$dir/node_modules" "$REPO_PATH/$dir/node_modules"
            echo_with_timestamp "Symlinked $dir/node_modules from pre-baked cache"
            # Store checksum on EFS (outside node_modules) so it persists across pod restarts
            md5sum "$REPO_PATH/$dir/package.json" | awk '{print $1}' > "$REPO_PATH/$dir/.npm-checksum"
        fi
    done
    # Seed .cline/skills into the OpenVSCode workspace folder (always server/, set by portal ?folder= URL)
    if [ -d "/opt/prebaked/.cline/skills" ]; then
        mkdir -p "$REPO_PATH/server/.cline/skills"
        cp -r /opt/prebaked/.cline/skills/. "$REPO_PATH/server/.cline/skills/"
        echo_with_timestamp "Seeded .cline/skills into $REPO_PATH/server/.cline/skills from pre-baked image cache"
    fi
else
    echo_with_timestamp "No pre-baked cache found. Cloning from scratch..."
    if ! git clone -b "$BRANCH" "$REPOSITORY" "$REPO_PATH"; then
        echo_with_timestamp "FATAL: Failed to clone repository $REPOSITORY"
        exit 1
    fi
fi

# Get the values from settings.json
echo_with_timestamp "Reading configuration from user.json"
USERNAME=$(jq -r '.user' /home/workspace/utils/user.json)

ATLAS_HOST=${ATLAS_SRV#mongodb+srv://}

# Create backend directory and .env based on backend type
if [ "$BACKEND_TYPE" != "" ]; then
    echo_with_timestamp "Creating $BACKEND_TYPE directory and .env file"
    mkdir -p "$REPO_PATH/$BACKEND_TYPE"

    cat <<EOL > "$REPO_PATH/$BACKEND_TYPE/.env"
PORT=5000
MONGODB_URI=mongodb+srv://${USERNAME}:${ATLAS_PWD}@${ATLAS_HOST}/?retryWrites=true&w=majority
DATABASE_NAME=${USERNAME}
EOL

    # Copy files only for backend type
    if [ "$BACKEND_TYPE" = "backend" ]; then
        echo_with_timestamp "Copying files to backend folder"
        
        # Validate source files exist before copying
        if [ ! -f "$REPO_PATH/docs/assets/files/swagger.json" ]; then
            echo_with_timestamp "FATAL: Required file swagger.json not found at $REPO_PATH/docs/assets/files/"
            exit 1
        fi
        
        if [ ! -d "$REPO_PATH/server/src/lab/rest-lab" ]; then
            echo_with_timestamp "FATAL: Required directory rest-lab not found at $REPO_PATH/server/src/lab/"
            exit 1
        fi
        
        cp "$REPO_PATH/docs/assets/files/swagger.json" "$REPO_PATH/backend/"
        cp -r "$REPO_PATH/server/src/lab/rest-lab" "$REPO_PATH/backend/"
    fi

    # Install dependencies only for server
    if [ "$BACKEND_TYPE" = "server" ]; then
        cd "$REPO_PATH/$BACKEND_TYPE"

        # Validate package.json exists
        if [ ! -f "package.json" ]; then
            echo_with_timestamp "FATAL: package.json not found in $REPO_PATH/$BACKEND_TYPE"
            exit 1
        fi

        # Skip npm install if node_modules is present and package.json has not changed.
        # Checksum is stored in .npm-checksum (on EFS, persists across restarts).
        # node_modules may be a symlink to /opt/prebaked/ (Option A) — handle both cases.
        SKIP_NPM=false
        CHECKSUM_FILE=".npm-checksum"
        CURRENT_HASH=$(md5sum "package.json" | awk '{print $1}')
        STORED_HASH=$(cat "$CHECKSUM_FILE" 2>/dev/null || echo "")

        if { [ -L "node_modules" ] || [ -d "node_modules" ]; } && [ "$CURRENT_HASH" = "$STORED_HASH" ]; then
            SKIP_NPM=true
            echo_with_timestamp "node_modules up to date (package.json unchanged), skipping npm install for $BACKEND_TYPE"
        fi

        if [ "$SKIP_NPM" = false ]; then
            # Remove symlink before npm install so npm creates a real node_modules on EFS
            if [ -L "node_modules" ]; then
                rm "node_modules"
                echo_with_timestamp "Removed node_modules symlink (package.json changed), running npm install"
            fi
            echo_with_timestamp "Installing server dependencies"
            MAX_RETRIES=3
            RETRY_COUNT=0
            NPM_SUCCESS=false

            while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
                echo_with_timestamp "Attempting npm install (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)..."

                if npm install --legacy-peer-deps 2>&1 | tee /tmp/npm-install-server.log; then
                    NPM_SUCCESS=true
                    echo_with_timestamp "npm install succeeded in $BACKEND_TYPE"
                    md5sum package.json | awk '{print $1}' > "$CHECKSUM_FILE"
                    break
                else
                    RETRY_COUNT=$((RETRY_COUNT + 1))
                    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                        echo_with_timestamp "npm install failed, retrying in 5 seconds..."
                        sleep 5
                    fi
                fi
            done

            if [ "$NPM_SUCCESS" = false ]; then
                echo_with_timestamp "FATAL: npm install failed in $BACKEND_TYPE after $MAX_RETRIES attempts"
                echo_with_timestamp "Last error output:"
                tail -50 /tmp/npm-install-server.log
                exit 1
            fi
        fi
    fi
fi

# Configure the MongoDB VSCode extension via workspace settings. These settings have
# "window" scope, so they are read from the folder OpenVSCode opens (always server/, set
# by the portal ?folder= URL). .vscode/ is gitignored, so this never conflicts with the
# git pull above. Settings are merged into any existing settings.json, and each feature
# is applied independently.
VSCODE_DIR="$REPO_PATH/server/.vscode"
MDB_JQ_FILTER=""
MDB_JQ_ARGS=()

# Pre-create the Atlas connection (mdb.presetConnections, extension >= 1.12.0).
if [ "$PRECONFIGURE_MDB_CONNECTION" = "true" ]; then
    if [ -z "$ATLAS_HOST" ]; then
        echo_with_timestamp "WARNING: preconfigure_mongodb_connection is enabled but Atlas SRV is empty, skipping"
    else
        # Percent-encode the password so special characters cannot break the URI
        ENCODED_PWD=$(jq -rn --arg p "$ATLAS_PWD" '$p|@uri')
        MDB_PRESET_URI="mongodb+srv://${USERNAME}:${ENCODED_PWD}@${ATLAS_HOST}/${USERNAME}?retryWrites=true&w=majority"

        MDB_JQ_FILTER='.["mdb.presetConnections"] = [{"name": $name, "connectionString": $uri}]'
        MDB_JQ_ARGS+=(--arg name "MongoDB Arena - ${USERNAME}" --arg uri "$MDB_PRESET_URI")
        echo_with_timestamp "Pre-configuring MongoDB extension connection for user $USERNAME"
    fi
else
    echo_with_timestamp "MongoDB extension connection pre-configuration disabled in scenario config"
fi

# Start the MCP server automatically instead of prompting the participant.
# mdb.mcp.server accepts "prompt" (default), "autoStartEnabled" or "autoStartDisabled";
# with autoStartEnabled the extension starts the server on activation and binds it to the
# active connection, so no prompt is shown.
if [ "$AUTOSTART_MCP_SERVER" = "true" ]; then
    if [ -n "$MDB_JQ_FILTER" ]; then
        MDB_JQ_FILTER="$MDB_JQ_FILTER | "
    fi
    MDB_JQ_FILTER="${MDB_JQ_FILTER}.[\"mdb.mcp.server\"] = \"autoStartEnabled\""
    echo_with_timestamp "Enabling MongoDB MCP server auto-start (mdb.mcp.server=autoStartEnabled)"
else
    echo_with_timestamp "MongoDB MCP server auto-start disabled in scenario config"
fi

if [ -n "$MDB_JQ_FILTER" ]; then
    echo_with_timestamp "Writing MongoDB extension settings to $VSCODE_DIR/settings.json"
    mkdir -p "$VSCODE_DIR"

    # Merge into any existing settings.json rather than overwriting it
    EXISTING_SETTINGS="{}"
    if [ -f "$VSCODE_DIR/settings.json" ]; then
        EXISTING_SETTINGS=$(jq '.' "$VSCODE_DIR/settings.json" 2>/dev/null || echo "{}")
    fi

    echo "$EXISTING_SETTINGS" | jq "${MDB_JQ_ARGS[@]}" "$MDB_JQ_FILTER" \
        > "$VSCODE_DIR/settings.json.tmp" \
        && mv "$VSCODE_DIR/settings.json.tmp" "$VSCODE_DIR/settings.json"

    echo_with_timestamp "MongoDB extension settings written successfully"
else
    echo_with_timestamp "No MongoDB extension settings to write"
fi

# Pre-configure the Cline extension with the LiteLLM provider, so participants skip the
# "Use your own API key" setup screen.
#
# Cline persists its own state to plain JSON files under $HOME/.cline/data (overridable
# with CLINE_DIR): non-secret settings in globalState.json, API keys in secrets.json
# (mode 0600). Both files are read at extension activation, so writing them here is
# enough — no VSCode setting is involved (Cline contributes none).
#
# planMode*/actMode* are set together so both Plan and Act modes use LiteLLM, and
# welcomeViewCompleted skips the onboarding screen. Only the keys we own are touched:
# existing files are merged, so a returning participant keeps their other preferences.
#
# The model MUST be set via planModeLiteLlmModelId/actModeLiteLlmModelId: the LiteLLM
# handler reads those two keys specifically (liteLlmModelId: r==="plan" ?
# e.planModeLiteLlmModelId : e.actModeLiteLlmModelId). A bare "liteLlmModelId" key is
# silently dropped — it is not in Cline's settings-defaults table, and only keys in that
# table are persisted. planMode/actModeApiModelId are set too so the UI shows the model.
#
# telemetrySetting defaults to "unset", which Cline treats as opted in (every check is
# `telemetrySetting !== "disabled"`). Because IDE telemetry is off in the baked Machine
# settings, that mismatch triggers the "Anonymous Cline error and usage reporting is
# enabled, but IDE telemetry is disabled" popup. Setting it to "disabled" turns off both
# usage and error reporting and suppresses the popup — it is the same value the extension
# writes when a user opts out. Note that the cline.telemetry.enabled VSCode setting in
# the image is a no-op: Cline 3.87 contributes no configuration properties.
if [ "$PRECONFIGURE_CLINE" = "true" ]; then
    if [ -z "$CLINE_BASE_URL" ] || [ -z "$CLINE_MODEL" ]; then
        echo_with_timestamp "WARNING: cline.preconfigure is enabled but base_url or model is empty, skipping"
    else
        # Written under /home/workspace (the EFS volume) rather than $HOME/.cline,
        # because this script runs in the init container and /config is a per-container
        # image layer that the main container does not share. The CLINE_DIR env var on
        # the main container points Cline at this directory.
        CLINE_DATA_DIR="/home/workspace/.cline/data"
        echo_with_timestamp "Pre-configuring Cline (LiteLLM, model $CLINE_MODEL) in $CLINE_DATA_DIR"
        mkdir -p "$CLINE_DATA_DIR"

        CLINE_GLOBAL_STATE="$CLINE_DATA_DIR/globalState.json"
        CLINE_SECRETS="$CLINE_DATA_DIR/secrets.json"

        EXISTING_GLOBAL="{}"
        if [ -f "$CLINE_GLOBAL_STATE" ]; then
            EXISTING_GLOBAL=$(jq '.' "$CLINE_GLOBAL_STATE" 2>/dev/null || echo "{}")
        fi

        echo "$EXISTING_GLOBAL" | jq \
            --arg baseUrl "$CLINE_BASE_URL" \
            --arg model "$CLINE_MODEL" \
            '. + {
                planModeApiProvider: "litellm",
                actModeApiProvider: "litellm",
                planModeLiteLlmModelId: $model,
                actModeLiteLlmModelId: $model,
                planModeApiModelId: $model,
                actModeApiModelId: $model,
                liteLlmBaseUrl: $baseUrl,
                welcomeViewCompleted: true,
                isNewUser: false,
                telemetrySetting: "disabled"
            }' \
            > "$CLINE_GLOBAL_STATE.tmp" \
            && mv "$CLINE_GLOBAL_STATE.tmp" "$CLINE_GLOBAL_STATE"

        EXISTING_SECRETS="{}"
        if [ -f "$CLINE_SECRETS" ]; then
            EXISTING_SECRETS=$(jq '.' "$CLINE_SECRETS" 2>/dev/null || echo "{}")
        fi

        # secrets.json holds credentials — create it with 0600 before writing.
        touch "$CLINE_SECRETS.tmp"
        chmod 600 "$CLINE_SECRETS.tmp"
        echo "$EXISTING_SECRETS" | jq \
            --arg apiKey "$CLINE_API_KEY" \
            '. + {liteLlmApiKey: $apiKey}' \
            > "$CLINE_SECRETS.tmp" \
            && mv "$CLINE_SECRETS.tmp" "$CLINE_SECRETS"
        chmod 600 "$CLINE_SECRETS"

        echo_with_timestamp "Cline pre-configured successfully"
    fi
else
    echo_with_timestamp "Cline pre-configuration disabled in scenario config"
fi

echo_with_timestamp "Creating $FRONTEND_TYPE directory and .env file"
mkdir -p "$REPO_PATH/$FRONTEND_TYPE"

cat <<EOL > "$REPO_PATH/$FRONTEND_TYPE/.env"
WORKSHOP_USER=/app
BACKEND_URL=https://${USERNAME}.${URL}/backend
EOL

echo_with_timestamp "Installing and building the app"
cd "$REPO_PATH/$FRONTEND_TYPE"

# Validate package.json exists for frontend
if [ ! -f "package.json" ]; then
    echo_with_timestamp "FATAL: package.json not found in $REPO_PATH/$FRONTEND_TYPE"
    exit 1
fi

# Skip npm install if node_modules is present and package.json has not changed.
# Checksum is stored in .npm-checksum (on EFS, persists across restarts).
# node_modules may be a symlink to /opt/prebaked/ (Option A) — handle both cases.
SKIP_NPM=false
CHECKSUM_FILE=".npm-checksum"
CURRENT_HASH=$(md5sum "package.json" | awk '{print $1}')
STORED_HASH=$(cat "$CHECKSUM_FILE" 2>/dev/null || echo "")

if { [ -L "node_modules" ] || [ -d "node_modules" ]; } && [ "$CURRENT_HASH" = "$STORED_HASH" ]; then
    SKIP_NPM=true
    echo_with_timestamp "node_modules up to date (package.json unchanged), skipping npm install for $FRONTEND_TYPE"
fi

if [ "$SKIP_NPM" = false ]; then
    # Remove symlink before npm install so npm creates a real node_modules on EFS
    if [ -L "node_modules" ]; then
        rm "node_modules"
        echo_with_timestamp "Removed node_modules symlink (package.json changed), running npm install"
    fi
    echo_with_timestamp "Installing app dependencies..."
    MAX_RETRIES=3
    RETRY_COUNT=0
    NPM_SUCCESS=false

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        echo_with_timestamp "Attempting npm install for $FRONTEND_TYPE (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)..."

        if npm install --legacy-peer-deps 2>&1 | tee /tmp/npm-install-frontend.log; then
            NPM_SUCCESS=true
            echo_with_timestamp "npm install succeeded in $FRONTEND_TYPE"
            md5sum package.json | awk '{print $1}' > "$CHECKSUM_FILE"
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                echo_with_timestamp "npm install failed, retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done

    if [ "$NPM_SUCCESS" = false ]; then
        echo_with_timestamp "FATAL: npm install failed in $FRONTEND_TYPE after $MAX_RETRIES attempts"
        echo_with_timestamp "Last error output:"
        tail -50 /tmp/npm-install-frontend.log
        exit 1
    fi
fi

# Always rebuild — .env now contains real BACKEND_URL, must produce correct build
echo_with_timestamp "Building the app..."
if ! npm run build 2>&1 | tee /tmp/npm-build-frontend.log; then
    echo_with_timestamp "FATAL: npm build failed in $FRONTEND_TYPE"
    echo_with_timestamp "Build error output:"
    tail -50 /tmp/npm-build-frontend.log
    exit 1
fi

# Source and call the lab exercises setup script conditionally
if [ "$BACKEND_TYPE" = "server" ]; then
    echo_with_timestamp "Server backend detected, checking if lab exercises setup is needed"
    
    # Check if enhanced scenario config exists and get total_answer_files_needed
    if [ -f "/home/workspace/scenario-config/enhanced-scenario-config.json" ]; then
        TOTAL_ANSWER_FILES_NEEDED=$(echo "$SCENARIO_CONFIG" | jq -r '.needed_answer_files.summary.total_answer_files_needed // 0')
        
        echo_with_timestamp "Total answer files needed: $TOTAL_ANSWER_FILES_NEEDED"
        
        # Only run setup if total_answer_files_needed is not zero
        if [ "$TOTAL_ANSWER_FILES_NEEDED" -ne 0 ]; then
            echo_with_timestamp "Answer files needed, setting up lab exercises"
            
            # Source the setup script and call the function
            source "$(dirname "$0")/setup_lab_exercises.sh"
            setup_lab_exercises
        else
            echo_with_timestamp "No answer files needed, skipping lab exercises setup"
        fi
    else
        echo_with_timestamp "Enhanced scenario config not found, skipping lab exercises setup"
    fi
fi

echo_with_timestamp "User operations script completed successfully."
