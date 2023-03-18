CURRENT_SUBSCRIPTION=$(az account show --query 'name' --output tsv)

if [[ "$CURRENT_SUBSCRIPTION" == "Omegapoint Lab" ]]; then

    #public
    NAME='devops-vnet-function-public'
    RESOURCE_GROUP=${NAME}

    echo "Deploying to ${CURRENT_SUBSCRIPTION}-${RESOURCE_GROUP}"

    az group create --location 'northeurope' --resource-group $RESOURCE_GROUP

    FUNCTION_PUBLIC_DEPLOYMENT_NAME=function-public-deploy-$(date '+%y%m%d-%H%M%S')
    az deployment group create \
            --resource-group $RESOURCE_GROUP \
            --template-file public/function.bicep  \
            --parameters name=${NAME}\
            --name $FUNCTION_PUBLIC_DEPLOYMENT_NAME

    mvn clean package -U --file public/java-function/pom.xml
    mvn azure-functions:deploy --file public/java-function/pom.xml

    #deny main site
    NAME='devops-vnet-function-deny-main-site'
    RESOURCE_GROUP=${NAME}

    echo "Deploying to ${CURRENT_SUBSCRIPTION}-${RESOURCE_GROUP}"

    az group create --location 'northeurope' --resource-group $RESOURCE_GROUP

    FUNCTION_MAIN_DEPLOYMENT_NAME=function-main-deploy-$(date '+%y%m%d-%H%M%S')
    az deployment group create \
            --resource-group $RESOURCE_GROUP \
            --template-file deny-public-access-to-main-site/function.bicep  \
            --parameters name=${NAME}\
            --name $FUNCTION_MAIN_DEPLOYMENT_NAME

    mvn clean package -U --file deny-public-access-to-main-site/java-function/pom.xml
    mvn azure-functions:deploy --file deny-public-access-to-main-site/java-function/pom.xml
else
  echo "Wrong subscription ($CURRENT_SUBSCRIPTION)"
fi