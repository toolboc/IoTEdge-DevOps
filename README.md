# IoTEdge-DevOps

A living repository of best practices and examples for developing [AzureIoT Edge](https://docs.microsoft.com/azure/iot-edge/?WT.mc_id=iot-0000-pdecarlo) solutions doubly presented as a hands-on-lab.

## Purpose

The [Internet of Things](https://en.wikipedia.org/wiki/Internet_of_things) is a technology paradigm that involves the use of internet connected devices to publish data often in conjunction with real-time data processing, machine learning, and/or storage services.  Development of these systems can be enhanced through application of modern DevOps principles which include such tasks as automation, monitoring, and all steps of the software engineering process from development, testing, quality assurance, and release.  We will examine these concepts as they relate to feature offerings in [Azure DevOps Services](https://azure.microsoft.com/services/devops?WT.mc_id=iot-0000-pdecarlo), [Application Insights](https://azure.microsoft.com/services/application-insights?WT.mc_id=iot-0000-pdecarlo), [Azure Container Registries](https://azure.microsoft.com/services/container-registry?WT.mc_id=iot-0000-pdecarlo), [Azure IoT Hub Device Provisioning Service](https://docs.microsoft.com/azure/iot-dps?WT.mc_id=iot-0000-pdecarlo), and [Azure IoT Hubs](https://azure.microsoft.com/services/iot-hub?WT.mc_id=iot-0000-pdecarlo).

## IoTEedge-DevOps Lab

This Lab will walk through creating an Azure DevOps Services project repo that employs [Continuous Integration](https://docs.microsoft.com/azure/devops/what-is-continuous-integration?WT.mc_id=iot-0000-pdecarlo) and [Continuous Delivery](https://docs.microsoft.com/azure/devops/what-is-continuous-delivery?WT.mc_id=iot-0000-pdecarlo) to publish an IoT Edge deployment to specific devices as part of a [build definition](https://docs.microsoft.com/cli/vsts/build/definition?WT.mc_id=iot-0000-pdecarlo) and [release pipeline](https://docs.microsoft.com/vsts/pipelines/release/?WT.mc_id=iot-0000-pdecarlo). 

* [Step 1: Creating Azure Resources](#step-1-creating-azure-resources)
* [Step 2: Setup Azure DevOps Services](#step-2-setup-azure-devops-services)
* [Step 3: Setting up Continuous Integration](#step-3-setting-up-continuous-integration)
* [Step 4: Creating a release pipeline with a Smoke Test](#step-4-creating-a-release-pipeline-with-a-smoke-test)
* [Step 5: Monitoring devices with App Insights](#step-5-monitoring-devices-with-app-insights)

### Step 1: Creating Azure Resources

To get started, we will need to create a few cloud services that will be used in later portions of the lab.  These services are outlined below, with a brief description of how they will be used in later steps.  

| Service | Description |
| -------------- | ------------|
| [Application Insights](https://azure.microsoft.com/services/application-insights?WT.mc_id=iot-0000-pdecarlo) | Used to monitor performance metrics of Docker Host and IoT Edge Modules |
| [Azure Container Registries](https://azure.microsoft.com/services/container-registry?WT.mc_id=iot-0000-pdecarlo) | A private docker registry service used to store published IoT Edge Modules |
| [Azure IoT Hub Device Provisioning Service](https://docs.microsoft.com/azure/iot-dps?WT.mc_id=iot-0000-pdecarlo) | Allows for automatic provisioning of IoT Devices in a secure and scalable manner |
| [Azure IoT Hubs](https://azure.microsoft.com/services/iot-hub?WT.mc_id=iot-0000-pdecarlo) | Service which enables us to securely connect, monitor, and manage IoT devices. 

If you have already deployed any of these services into an existing environment, you are welcome to reuse them in the lab, however, it is highly suggested to create brand new services to avoid issues.  

Deploy the required services by clicking 'Deploy to Azure' button below:

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftoolboc%2FIoTEdge-DevOps%2Fmaster%2Fazuredeploy.json)

On the resulting screen, supply a globally unique value for the `Resource Name Suffix` parameter:

![Deploy to Azure](/content/DeployToAzure.PNG)

If you encounter any issues in the deployment, it is advised to delete the created Resource Group (if any) and retry with a new value for the `Resource Name Suffix` parameter.

### Step 2: Setup Azure DevOps Services

Azure DevOps Services allows for building, testing, and deploying code in an easy to manage interface.  We will build out a base for IoT Edge DevOps practices using services provided by Azure DevOps Services.

If you have not already, create a new Azure DevOps Services account [here](https://azure.microsoft.com/services/devops?WT.mc_id=iot-0000-pdecarlo)

Next, create a new project and give it a descriptive name:

![Create Project](/content/CreateProjectVSTS.PNG)

Next, select `Repos` then click the `import` button underneath "import a repository" and supply this url:

    https://github.com/toolboc/IoTEdge-DevOps.git

![Import GH to Azure DevOps](/content/ImportGHtoVSTS.PNG)

The import process should begin importing this repository into your Azure DevOps project. 

### Step 3: Setting up Continuous Integration

This repository contains an Azure DevOps build definition which is preconfigured to build the included EdgeSolution in [.azure-pipelines.yml](/.azure-pipelines.yml).  This build definition relies on an external plugin ([Replace Tokens](https://marketplace.visualstudio.com/items?itemName=qetza.replacetokens&WT.mc_id=iot-0000-pdecarlo)).

Begin by installing the **Replace Tokens** task from the Visual Studio Marketplace by visiting this [link](https://marketplace.visualstudio.com/items?itemName=qetza.replacetokens&WT.mc_id=iot-0000-pdecarlo) and clicking the "Get it free" button, then install into the organization which contains your newly created Azure DevOps project.

Once this task is successfully installed, return to the Azure DevOps project and select "Repos => Files" then edit the `.azure-pipelines.yml` file:

![Edit Build Definition](/content/EditBuildDefVSTS.PNG)

Add the following comment to the top of the file as shown below:

    # This repository is built using Azure DevOps.

Commit the changes as shown:

![Commit Build Definition](/content/CommitBuildDefVSTS.PNG)

Navigate back to "Repos" and select "Set up build" then select "Run" and you should see that a build has kicked off upon editing the Build Definition:

![Created Build Definition](/content/BuildDefCreated.PNG)

The build will fail, this is to be expected as we need to add a few build variables in order for the build to run successfully.  We will need to obtain the hostname of the Azure Container Registry which will be represented by `acr.host`, in addition we will need the Azure Container Registry username which will be represented by `acr.user`, and finally the Azure Container Registry password which will be represented by `acr.password`.  All of these can be obtained in the Azure portal by viewing your created Azure Container Registry and selecting
 "Access Keys" as shown below:

![Azure Container Registry](/content/ACR.PNG)

Next, we need to obtain the Application Insights instrumentation key which will be represented by `appinsights.instrumentationkey`.  This can be obtained in the Azure portal by viewing your created Application Insight Resource as shown below:

![Application Insights](/content/AppInsights.PNG)

Once you have obtained all of the necessary values, create a build definition variable for `acr.host`, `acr.user`, `acr.password`, and `appinsights.instrumentationkey` as shown below:

![Edit Build Definition Variables](/content/EditBuildDefVars.PNG)

![Build Definition Variables](/content/BuildDefVars.PNG)

Finally, select the "Run" button and click "Run" in the dialogue as shown below:

![Queue Build Definition](/content/QueueBuildVSTS.PNG)

The build should complete successfully as shown below:

![Queue Build Definition](/content/BuildSuccessVSTS.PNG)

With a successful build definition in place, we can now enforce continuous integration by applying a branch policy to the master branch.  Start by selecting "Repos" => "Branches" then click the "..." on the row for the master branch and select "Branch policies".

![Select Branch Policy](/content/SelectBranchPolicyVSTS.PNG)

Next, under "Build validation", click "Add build policy" and select the newly created Build pipeline then click the "Save" button.

![Configure Build Policy](/content/BuildPolicyVSTS.PNG)

While this policy is enabled, all commits to feature branches will kick off an execution of the newly created Build pipeline and it must succeed in order for a pull request of those changes to be made to the master branch.

### Step 4: Creating a release pipeline with a Smoke Test

Deployments to devices need to be done under tight control in production environments.  To achieve this, we will create a release pipeline which deploys to QA devices and smoke tests the edge runtime in a containerized device.  This is accomplished by running an instance of the [azure-iot-edge-device-container](https://github.com/toolboc/azure-iot-edge-device-container) which is configured as a QA device then probing the IoT Hub to ensure that QA device receives the desired deployment configuration and is able to successfully run all configured modules.  This test is contained in [edgeSmokeTest.sh](/scripts/edgeSmokeTest.sh)

To begin, select "Pipelines" => "Releases" then create a new pipeline with an empty job and save it:

![Create Empty Job](/content/EmptyJobVSTS.PNG)

Now head back to "Build and release" => "Releases" => "New" and select "Import a pipeline":

![Import a pipeline](/content/ImportAPipelineVSTS.PNG)

Download the [release-pipeline.json](/release-pipeline.json) file located in the root of this repo and import it:

![The initial pipeline](/content/InitialPipelineVSTS.PNG)

There are a few things that we will need to fix before we can successfully run the Release Pipeline, specifically Azure Subscription endpoints, Agent Pools, and variable settings, and artifact source. 

To fix the Azure Subscription Endpoints, select "Tasks" => "Create Deployment" and supply the appropriate Azure subscription and Azure Container Registry for the "Azure IoT Edge - Push module images" and "Azure IoT Edge - Deploy to IoT Edge devices" tasks:

![Fix Endpoints 1](/content/FixAzureEndpoints1.PNG)

![Fix Endpoints 2](/content/FixAzureEndpoints2.PNG)

Next select Tasks" => "Smoke Test" and supply the appropriate Azure subscription and Azure Container Registry for the "Remove all registered QA devices" and "Smoke Test" tasks:

![Fix Endpoints 3](/content/FixAzureEndpoints3.PNG)

![Fix Endpoints 4](/content/FixAzureEndpoints4.PNG)

To fix the Agent Pools, select "Tasks" => "Create Deployment" => "Agent Job" and change the Agent Pool to "Azure Pipelines" and set Agent Specification to "ubuntu-18.04":

![Fix Agent Pool 1](/content/AgentPool1.PNG)

![Fix Agent Pool 2](/content/AgentPool2.PNG)

With these fixes applied, you should be able to save the Release pipeline.  It is highly recommended to save at this point if Azure DevOps allows.

To fix the variables, select "Variables":

![Pipeline Variables](/content/PipelineVarsVSTS.PNG)

We will need to modify all variables in brackets (<>)

You may use the same values for `acr.host`, `acr.user`, `acr.password`, and `appinsights.instrumentationkey` that were used in the CI build definition in step 3.
`iothub_name` is the name of the iot hub that was created in step 1.

For the additional variables, we need to create a service principal by performing the following:

Install the [Azure-Cli](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest&WT.mc_id=iot-0000-pdecarlo) 

Run `az login` to sign in with the azure cli, then run `az account list` to see available subscriptions, and set the appropriate subscription with:

    az account set --subscription <subscriptionid>

Create a Service Principal for your subscription with the azure cli (it is suggested to use a value of 'IoTEdge-DevOps' or similar for <name>):

    az ad sp create-for-rbac --name <name>

You should see output similar to:

    {
    "appId": "12345678-1234-1234-1234-1234567890ab",
    "displayName": "IoTEdge-DevOps",
    "name": "http://IoTEdge-DevOps",
    "password": "MyPassword",
    "tenant": "abcdefgh-abcd-abcd-abcd-abcdefghijkl"
    }

Take note of the `name`, `password`, and `tenant` as these values will be used  for `spAppURl`, `spPassword`, and `tenant` respectively.  Note: that some passwords could be generated with characters that can cause issues when interpreted from the Linux command line. If this is the case, for example if the resulting password contains a "` ! $", then you can either regenerate a new password by re-running the command above or you could try to wrap this value with single quotes i.e. '<password>'. Any failures that may arise in the "Smoke Test" are usually attributed to these values.  

Obtain the following Parameters and supply the appropriate values for the remaining release pipeline variables:

| Parameter      | Description |           |
| -------------- | ------------| --------- |
| spAppUrl      | The Service Principal app URL | Required  |
| spPassword   | The Password for the Service Principal | Required |
| tenantId   | The tenant id for the Service Principal | Required |
| subscriptionId   | The azure subscription id where the IoT Hub is deployed | Required |

To test these parameters on a local Docker on Linux instance to rule out any potential issues, you can use the following command:

`
docker run -d -e spAppUrl=<spAppURl> -e spPassword=<spPassword> -e tenantId=<tenantId> -e subscriptionId=<subscriptionId> -e iothub_name=<iothub_name> -e environment=qa --name qa-test --restart no -v /var/run/docker.sock:/var/run/docker.sock toolboc/azure-iot-edge-device-container
`

If the container fails to start, there is likely an issue with the parameters provided.  If these fail locally, they will also likely fail in the release build.

Once you have properly set the variables for the Release, we need to fix the artifact source, select "Pipeline => Add an artifact":

![Add New Artifact](/content/AddNewArtifact.PNG)

Next, select your CI build pipeline as source and configure to obtain the latest version:

![Add New Artifact](/content/AddNewArtifact2.PNG)

Once you have configured everything appropriately, select "Save" then "Pipelines" => "Releases" then select the newly created Release pipeline and "Create a release":

![Create a Release](/content/CreateReleaseVSTS.PNG)

The new release pipeline should begin running:

![Running Release](/content/RunningReleaseVSTS.PNG)

### Step 5: Monitoring devices with App Insights

Monitoring allows us to perform long running tests against edge modules and provide real-time alerts using Application Insights.  Our EdgeSolution includes a dockerappinsights module which is configured in [deployment.template.json](/EdgeSolution/deployment.template.json).  This module monitors the docker host of each containerized IoT Edge device.

Assuming a device has been deployed and is running, you can monitor the device by viewing the Appication Insights resource deployed in step 1.  

![App Insights Graph](/content/AppInsightsGraph.PNG)

To configure a chart, select "Metrics Explorer" => "Add Chart" => "Edit Chart" and add the following to monitor Block IO for all Edge modules:

![App Insights Block IO](/content/AIBlkio.PNG)

Add the following to monitor the network traffic for all Edge modules:

![App Insights Block IO](/content/AINetworkTraffic.PNG)


