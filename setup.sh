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

    #self hosted agent
    NAME='devops-vnet-function-self-hosted-agent'
    RESOURCE_GROUP=${NAME}

    echo "Deploying to ${CURRENT_SUBSCRIPTION}-${RESOURCE_GROUP}"

    az group create --location 'northeurope' --resource-group $RESOURCE_GROUP

    FUNCTION_SELF_HOSTED_AGENT_DEPLOYMENT_NAME=function-self-hosted-agent-deploy-$(date '+%y%m%d-%H%M%S')
    az deployment group create \
            --resource-group $RESOURCE_GROUP \
            --template-file self-hosted-agent/function.bicep  \
            --parameters name=${NAME}\
            --name $FUNCTION_SELF_HOSTED_AGENT_DEPLOYMENT_NAME

    #Connect the agent to DevOps
    #https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops
    #Generate PAT in DevOps
    # Agent Pools (read, manage)
    # Deployment group (read, manage)
    #
    #Configure the VM
    #mkdir myagent && cd myagent
    #wget https://vstsagentpackage.azureedge.net/agent/2.217.2/vsts-agent-linux-x64-2.217.2.tar.gz
    #tar zxvf vsts-agent-linux-x64-2.217.2.tar.gz
    #./config.sh --unattended \
    #    --url "https://dev.azure.com/<INSERT_NAME_HERE>" \
    #    --auth PAT \
    #    --token "<INSERT_TOKEN_HERE>" \
    #    --pool "<INSERT_POOL_NAME_HERE>" \
    #    --replace \
    #    --acceptTeeEula & wait $!
    #./run.sh
else
  echo "Wrong subscription ($CURRENT_SUBSCRIPTION)"
fi