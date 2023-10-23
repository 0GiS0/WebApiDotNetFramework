# Load secrets
set -o allexport; source .env; set +o allexport

az upgrade

RESOURCE_GROUP="jobs-sample"
LOCATION="francecentral"
ENVIRONMENT="env-jobs-sample"
JOB_NAME="github-actions-runner-job"

az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION"

az containerapp env create \
    --name "$ENVIRONMENT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION"

REPO_OWNER="0gis0"
REPO_NAME="WebApiDotNetFramework"

CONTAINER_IMAGE_NAME="github-actions-runner:1.0"
CONTAINER_REGISTRY_NAME="ghrunnerregistry"

az acr create \
    --name "$CONTAINER_REGISTRY_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Basic \
    --admin-enabled true

az acr build \
    --registry "$CONTAINER_REGISTRY_NAME" \
    --image "$CONTAINER_IMAGE_NAME" \
    --file "Dockerfile.github" \
    "https://github.com/Azure-Samples/container-apps-ci-cd-runner-tutorial.git"

az containerapp job create -n "$JOB_NAME" -g "$RESOURCE_GROUP" --environment "$ENVIRONMENT" \
    --trigger-type Event \
    --replica-timeout 1800 \
    --replica-retry-limit 1 \
    --replica-completion-count 1 \
    --parallelism 1 \
    --image "$CONTAINER_REGISTRY_NAME.azurecr.io/$CONTAINER_IMAGE_NAME" \
    --min-executions 0 \
    --max-executions 10 \
    --polling-interval 30 \
    --scale-rule-name "github-runner" \
    --scale-rule-type "github-runner" \
    --scale-rule-metadata "github-runner=https://api.github.com" "owner=$REPO_OWNER" "runnerScope=repo" "repos=$REPO_NAME" "targetWorkflowQueueLength=1" \
    --scale-rule-auth "personalAccessToken=personal-access-token" \
    --cpu "2.0" \
    --memory "4Gi" \
    --secrets "personal-access-token=$GITHUB_PAT" \
    --env-vars "GITHUB_PAT=secretref:personal-access-token" "REPO_URL=https://github.com/$REPO_OWNER/$REPO_NAME" "REGISTRATION_TOKEN_API_URL=https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runners/registration-token" \
    --registry-server "$CONTAINER_REGISTRY_NAME.azurecr.io"

az containerapp job execution list \
    --name "$JOB_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --output table \
    --query '[].{Status: properties.status, Name: name, StartTime: properties.startTime}'

az containerapp  \
    --name "$JOB_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --output table \
    --query '[].{Status: properties.status, Name: name, StartTime: properties.startTime}'

docker login -u winvmiisdogacr -p TRi9j9vcjkeyXxcDNz9Tn8Ax42hJaG0mj52jBsaQq3+ACRCcEzzO winvmiisdogacr.azurecr.io
docker run -e GITHUB_PAT=$GITHUB_PAT -e REPO_URL=https://github.com/$REPO_OWNER/$REPO_NAME -e REGISTRATION_TOKEN_API_URL=https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runners/registration-token winvmiisdogacr.azurecr.io/github-actions-runner:1.0

docker login -u ghrunnerregistry -p EMie27K5D9p4yfvFfDOVvfHUzvlQcJQh1nLe5ZoC1y+ACRCFJcO4 ghrunnerregistry.azurecr.io
docker run \
-e GITHUB_PAT=$GITHUB_PAT \
-e REPO_URL=https://github.com/$REPO_OWNER/$REPO_NAME \
-e REGISTRATION_TOKEN_API_URL=https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runners/registration-token \
ghrunnerregistry.azurecr.io/github-actions-runner:1.0


az containerapp logs show \
    --name "gh-runner" \
    --resource-group "win-vm-iis-goat-rg" \
    --follow