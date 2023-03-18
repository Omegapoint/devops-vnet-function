CURRENT_SUBSCRIPTION=$(az account show --query 'name' --output tsv)

if [[ "$CURRENT_SUBSCRIPTION" == "Omegapoint Lab" ]]; then
    NAME='kompetensdag'
    RESOURCE_GROUP=${NAME}-lab

    echo "Deploying to ${CURRENT_SUBSCRIPTION}-${RESOURCE_GROUP}"

    az group create --location 'northeurope' --resource-group $RESOURCE_GROUP

    INFRA_DEPLOYMENT_NAME=infra-deploy-$(date '+%y%m%d-%H%M%S')
    az deployment group create \
            --resource-group $RESOURCE_GROUP \
            --template-file infra.bicep  \
            --parameters appName=${NAME}\
            --name $INFRA_DEPLOYMENT_NAME

    ACR_NAME=$(az deployment group show \
            --resource-group $RESOURCE_GROUP \
            --name $INFRA_DEPLOYMENT_NAME \
            --query properties.outputs.acrName.value \
            --output tsv)

    IDENTITY_NAME=$(az deployment group show \
            --resource-group $RESOURCE_GROUP \
            --name $INFRA_DEPLOYMENT_NAME \
            --query properties.outputs.identityName.value \
            --output tsv)
    
    ENVIRONMENT_NAME=$(az deployment group show \
            --resource-group $RESOURCE_GROUP \
            --name $INFRA_DEPLOYMENT_NAME \
            --query properties.outputs.environmentName.value \
            --output tsv)

    ENVIRONMENT_DEFAULT_DOMAIN=$(az deployment group show \
            --resource-group $RESOURCE_GROUP \
            --name $INFRA_DEPLOYMENT_NAME \
            --query properties.outputs.environmentDefaultDomain.value \
            --output tsv)

    az acr login -n $ACR_NAME

    #Setup student-service
    STUDENT_SERVICE_NAME='student-service'
    STUDENT_SERVICE_VERSION='1.0.0'

    STUDENT_SERVICE_TAG="${STUDENT_SERVICE_NAME}:${STUDENT_SERVICE_VERSION}"
    mvn clean package -U --file student-service/pom.xml

    #For ARM mac
    docker buildx build --platform linux/amd64 --tag $ACR_NAME.azurecr.io/${STUDENT_SERVICE_TAG} --file student-service/Dockerfile student-service/
    #For other platforms
    #docker  build --tag $ACR_NAME.azurecr.io/${STUDENT_SERVICE_TAG} student-service/
    
    docker push $ACR_NAME.azurecr.io/${STUDENT_SERVICE_TAG}

    STUDENT_SERVICE_DEPLOYMENT_NAME=student-service-deploy-$(date '+%y%m%d-%H%M%S')
    az deployment group create \
            --resource-group $RESOURCE_GROUP \
            --template-file app.bicep  \
            --parameters identityName=${IDENTITY_NAME} \
              acrName=${ACR_NAME} \
              environmentName=${ENVIRONMENT_NAME} \
              name=${STUDENT_SERVICE_NAME} \
              version=${STUDENT_SERVICE_VERSION} \
              external=false \
              environmentVariables='[]' \
            --name $STUDENT_SERVICE_DEPLOYMENT_NAME

    #Setup engine
    ENGINE_NAME='engine'
    ENGINE_VERSION='1.0.0'

    ENGINE_TAG="${ENGINE_NAME}:${ENGINE_VERSION}"
    mvn clean package -U --file engine/pom.xml

    #For ARM mac
    docker buildx build --platform linux/amd64 --tag $ACR_NAME.azurecr.io/${ENGINE_TAG} --file engine/Dockerfile engine/
    #For other platforms
    #docker  build --tag $ACR_NAME.azurecr.io/${ENGINE_TAG} engine/

    docker push $ACR_NAME.azurecr.io/${ENGINE_TAG}

    ENGINE_DEPLOYMENT_NAME=engine-deploy-$(date '+%y%m%d-%H%M%S')
    az deployment group create \
            --resource-group $RESOURCE_GROUP \
            --template-file app.bicep  \
            --parameters identityName=${IDENTITY_NAME} \
              acrName=${ACR_NAME} \
              environmentName=${ENVIRONMENT_NAME} \
              name=${ENGINE_NAME} \
              version=${ENGINE_VERSION} \
              external=true \
              environmentVariables="[{\"name\":\"ENVIRONMENT_DEFAULT_DOMAIN\", \"value\": \"${ENVIRONMENT_DEFAULT_DOMAIN}\"}]"  \
            --name $ENGINE_DEPLOYMENT_NAME

    #Test
    echo  curl https://engine.${ENVIRONMENT_DEFAULT_DOMAIN}/api/v1/students
    curl https://engine.${ENVIRONMENT_DEFAULT_DOMAIN}/api/v1/students
else
  echo "Wrong subscription ($CURRENT_SUBSCRIPTION)"
fi