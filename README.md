# IoTEdge-DevOps

A living repository of best practices and examples for developing [AzureIoT Edge](https://docs.microsoft.com/en-us/azure/iot-edge/) solutions doubly presented as a hands-on-lab.

## Purpose

The [Internet of Things](https://en.wikipedia.org/wiki/Internet_of_things) is a technology paradigm that involves the use of internet connected devices to publish data often in conjunction with real-time data processing, machine learning, and/or storage services.  Development of these systems can be enhanced through application of modern DevOps principles which include such tasks as automation, monitoring, and all steps of the software engineering process from development, testing, quality assurance, and release.  We will examine these concepts as they relate to feature offerings in [Visual Studio Team Services](https://visualstudio.microsoft.com/team-services/), [Application Insights](https://azure.microsoft.com/en-us/services/application-insights/), [Azure Container Registries](https://azure.microsoft.com/en-us/services/container-registry/), [Azure IoT Hub Device Provisioning Service](https://docs.microsoft.com/en-us/azure/iot-dps/), and [Azure IoT Hubs](https://azure.microsoft.com/en-us/services/iot-hub/).

## IoTEedge-DevOps Lab

This Lab will walk through creating a Visual Studio Team Services project repo that employs [Continuous Integration](https://docs.microsoft.com/en-us/azure/devops/what-is-continuous-integration) and [Continuous Delivery](https://docs.microsoft.com/en-us/azure/devops/what-is-continuous-delivery) to publish an IoT Edge deployment to specific devices as part of a [build definition](https://docs.microsoft.com/en-us/cli/vsts/build/definition) and [release pipeline](https://docs.microsoft.com/en-us/vsts/pipelines/release/). 

### Step 1: Creating Azure Resources

To get started, we will need to create a few cloud services that will be used in later portions of the lab.  These services are outlined below, with a brief description of how they will be used in later steps.  

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://azuredeploy.net/)