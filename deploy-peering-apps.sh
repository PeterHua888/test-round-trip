# 1. UK South App
APP_RG_NAME="rg-test-app" # resource group name for app service, app service plan and vnet
APP_REGION_UK='uksouth' # region for app
ACR_NAME='testacreastasia001' # container registry name
APP_NAME_UK='test-app-uksouth-001' # app name
ASP_NAME_UK='test-asp-uksouth-001' # app service plan name
VNET_NAME_UK='test-uksouth-vn' # vnet name
VNET_ADDRESS_UK='10.13.0.0/16'
GATEWAY_SUBNET_ADDRESS_UK='10.13.0.0/24'
SUBNET_ADDRESS_UK='10.13.1.0/24'
COMMIT=$(git rev-parse --short HEAD) # Git commit version
IMAGE_TAG="v0.0.1-${COMMIT}" # docker tag name (versioning)
IMAGE_NAME_UK="${APP_NAME_UK}:${IMAGE_TAG}" # docker image name (repo:tag)

# 2. East Asia App
APP_REGION_HK='eastasia' # region for app
APP_NAME_HK='test-app-eastasia-001' # app name
ASP_NAME_HK='test-asp-eastasia-001' # app service plan name
VNET_NAME_HK='test-eastasia-vn' # vnet name
VNET_ADDRESS_HK='10.12.0.0/16'
GATEWAY_SUBNET_ADDRESS_HK='10.12.0.0/24'
SUBNET_ADDRESS_HK='10.12.1.0/24'
IMAGE_NAME_HK="${APP_NAME_HK}:${IMAGE_TAG}" # docker image name (repo:tag)

# App Settings
CONTAINER_PORT='8000' # app service port number
SERVER_ENVIRONMENT='prod'
ACR_USE_MANAGED_IDENTITY_CREDS='true' # True for Managed Identity; False for Admin Credential
VNET_ROUTE_ALL_ENABLED='true' # set VNet Route All to True
CLIENT_AFFINITY_ENABLED='false' # set ARR Affinity to Off
HTTP_LOGS_ENABLED='true' # enable application logs
declare -i HTTP_LOGS_RETENTION_DAYS=14  # application log retention days
declare -i HTTP_HTTP_LOGS_RETENTION_MB=100 # application log retention mb

# create resource group if not exist
if [ $(az group exists --name $APP_RG_NAME) = false ]; then
    az group create --name $APP_RG_NAME --location $APPREGION
fi

# deploy Azure Container Registry
if [[ $(az acr list --resource-group $APP_RG_NAME --query "[?name=='$ACR_NAME'] | length(@)") > 0 ]]
then
  echo "ACR exists"
  ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)
else
  echo "ACR doesn't exist, creating a new one"
  az deployment group create \
    --resource-group $APP_RG_NAME \
    --name acr-deployment \
    --template-file ./modules/acr.bicep \
    --parameters name=$ACR_NAME
  ACR_LOGIN_SERVER=$(az deployment group show -n acr-deployment -g $APP_RG_NAME --query properties.outputs.acrLoginServer.value -o tsv)
fi

# get ACR details
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query 'passwords[0].value' -o tsv)

# build and push container for UK
docker login -u $ACR_NAME -p $ACR_PASSWORD $ACR_LOGIN_SERVER
docker build --platform linux/amd64 -f Dockerfile.uksouth -t "${ACR_LOGIN_SERVER}/${IMAGE_NAME_UK}" .
docker push "${ACR_LOGIN_SERVER}/${IMAGE_NAME_UK}"

# build and push container for HK
docker build --platform linux/amd64 -f Dockerfile.eastasia -t "${ACR_LOGIN_SERVER}/${IMAGE_NAME_HK}" .
docker push "${ACR_LOGIN_SERVER}/${IMAGE_NAME_HK}"

# app deployment
az deployment group create \
    --resource-group $APP_RG_NAME \
    --name infra-deployment \
    --template-file ./main.bicep \
    --parameters acrName=$ACR_NAME \
    --parameters appNameUK=$APP_NAME_UK \
    --parameters appNameHK=$APP_NAME_HK \
    --parameters aspNameUK=$ASP_NAME_UK \
    --parameters aspNameHK=$ASP_NAME_HK \
    --parameters vnetNameUK=$VNET_NAME_UK \
    --parameters vnetNameHK=$VNET_NAME_HK \
    --parameters regionUK=$APP_REGION_UK \
    --parameters regionHK=$APP_REGION_HK \
    --parameters imageNameAndTagUK=$IMAGE_NAME_UK \
    --parameters imageNameAndTagHK=$IMAGE_NAME_HK \
    --parameters containerPort=$CONTAINER_PORT \
    --parameters vnetAddressUK=$VNET_ADDRESS_UK \
    --parameters vnetAddressHK=$VNET_ADDRESS_HK \
    --parameters gatewaySubnetAddressUK=$GATEWAY_SUBNET_ADDRESS_UK \
    --parameters gatewaySubnetAddressHK=$GATEWAY_SUBNET_ADDRESS_HK \
    --parameters integrationSubnetAddressUK=$SUBNET_ADDRESS_UK \
    --parameters integrationSubnetAddressHK=$SUBNET_ADDRESS_HK \
    --parameters acrUseManagedIdentityCreds=$ACR_USE_MANAGED_IDENTITY_CREDS \
    --parameters vnetRouteAllEnabled=$VNET_ROUTE_ALL_ENABLED \
    --parameters clientAffinityEnabled=$CLIENT_AFFINITY_ENABLED \
    --parameters httpLogsEnabled=$HTTP_LOGS_ENABLED \
    --parameters httpLogsRetentionDays=$HTTP_LOGS_RETENTION_DAYS \
    --parameters httpLogsRetentionMb=$HTTP_HTTP_LOGS_RETENTION_MB \
    --parameters serverEnvironment=$SERVER_ENVIRONMENT

