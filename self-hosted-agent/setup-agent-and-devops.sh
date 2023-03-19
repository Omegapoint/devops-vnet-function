#Create a PAT and an agent pool in DevOps with the name "MyPool".
#https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops
#Generate PAT in DevOps
# Agent Pools (read, manage)
# Deployment group (read, manage)

#Configure the VM
mkdir myagent && cd myagent
wget https://vstsagentpackage.azureedge.net/agent/2.214.1/vsts-agent-linux-x64-2.214.1.tar.gz
tar zxvf vsts-agent-linux-x64-2.214.1.tar.gz
./config.sh
sudo ./svc.sh install &
./runsvc.sh &
sudo apt-get install default-jdk -y
sudo apt update && sudo apt install maven -y
mvn --version
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash