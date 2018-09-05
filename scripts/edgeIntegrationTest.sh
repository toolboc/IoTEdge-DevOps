#!/bin/bash

# IoT Edge Integration Test Script
# Requires jq & azure cli with iot extension - https://docs.microsoft.com/en-us/azure/iot-hub/iot-hub-device-management-iot-extension-azure-cli-2-0

EdgeAgentTwinRequestThrottleInSeconds=5

usage(){
        echo "***Azure IoT Edge Integration Test Script***"
        echo "Usage: ./edgeIntegrationTest.sh <iothub.name> <environment> <deployment_name>"
}

startTest(){
qaDevices=($(az iot hub query --hub-name $iothub_name --query-command "SELECT * FROM devices WHERE tags.environment = '$environment'" | jq -r .[].deviceId))

if [ ${#qaDevices[*]} -eq 0 ]
then
        echo "No QA Devices found in $iothub_name"
        return 1
else
        echo "Number of QA Devices found in $iothub_name: ${#qaDevices[*]}"
fi

validateDevicesConnectedToIoTHub
validateDevicesAppliedDeployment
validateDevicesModulesRunning

}

getEdgeAgentTwin()
{
sleep $EdgeAgentTwinRequestThrottleInSeconds
edgeAgentTwin=$(az iot hub module-twin show --module-id '$edgeAgent' --hub-name $iothub_name --device-id $device)
}

validateDevicesConnectedToIoTHub(){
echo "Validating that all QA devices are curently connected to the iot hub..."
for device in ${qaDevices[*]}
do
        getEdgeAgentTwin
        connectionStatus=unknown
        while [ $connectionStatus != "Connected" ]
        do
                connectionStatus=$(echo $edgeAgentTwin | jq -r .connectionState)
                echo $device : $connectionStatus

                if [ $connectionStatus != "Applied" ]
                then
                        getEdgeAgentTwin
                fi
        done
done
}

validateDevicesAppliedDeployment(){
echo "Validating that all QA devices have applied the $deployment_name deployment..."
for device in ${qaDevices[*]}
do
        getEdgeAgentTwin
        deploymentStatus=unknown
        while [ $deploymentStatus != "Applied" ]
        do
                deploymentStatus=$(echo $edgeAgentTwin | jq -r .configurations[\"$deployment_name\"].status)
                echo $device : $deploymentStatus

                if [ $deploymentStatus != "Applied" ]
                then
                        getEdgeAgentTwin
                fi

        done
done
}

validateDevicesModulesRunning(){
echo "Validating that all QA devices configured modules are running..."
for device in ${qaDevices[*]}
do
        getEdgeAgentTwin
        deviceModules=($(echo $edgeAgentTwin | jq -r .properties.desired.modules | jq -r to_entries[].key))
        echo "Number of modules configured for $device: ${#deviceModules[*]}"

        for deviceModule in ${deviceModules[*]}
        do
                moduleStatus=unknown
                while [ $moduleStatus != "running" ]
                do
                        moduleStatus=$(echo $edgeAgentTwin | jq -r .properties.reported.modules[\"$deviceModule\"].runtimeStatus)
                        echo $deviceModule : $moduleStatus

                        if [ $moduleStatus != "running" ]
                        then
                                getEdgeAgentTwin
                        fi
                done
        done
done
}

iothub_name=$1
environment=$2
deployment_name=$3

# Check Arguments
[ "$#" -ne 3 ] && { usage && exit 1; } || startTest