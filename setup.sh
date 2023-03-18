CURRENT_SUBSCRIPTION=$(az account show --query 'name' --output tsv)

if [[ "$CURRENT_SUBSCRIPTION" == "Omegapoint Lab" ]]; then

    #public
    NAME='devops-vnet-function-public'
    RESOURCE_GROUP=${NAME}

    echo "Deploying to ${CURRENT_SUBSCRIPTION}-${RESOURCE_GROUP}"

    az group create --location 'northeurope' --resource-group $RESOURCE_GROUP

    FUNCTION_DEPLOYMENT_NAME=function-deploy-$(date '+%y%m%d-%H%M%S')
    az deployment group create \
            --resource-group $RESOURCE_GROUP \
            --template-file public/function.bicep  \
            --parameters name=${NAME}\
            --name $FUNCTION_DEPLOYMENT_NAME

    mvn clean package -U --file public/java-function/pom.xml
    mvn azure-functions:deploy --file public/java-function/pom.xml

    #
else
  echo "Wrong subscription ($CURRENT_SUBSCRIPTION)"
fi