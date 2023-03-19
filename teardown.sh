CURRENT_SUBSCRIPTION=$(az account show --query 'name' --output tsv)

if [[ "$CURRENT_SUBSCRIPTION" == "Omegapoint Lab" ]]; then
    az group delete --yes --name devops-vnet-function-public
    az group delete --yes --name devops-vnet-function-deny-main-site
    az group delete --yes --name devops-vnet-function-self-hosted-agent
else
  echo "Wrong subscription ($CURRENT_SUBSCRIPTION)"
fi