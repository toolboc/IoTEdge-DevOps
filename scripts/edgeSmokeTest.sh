#!/bin/bash
# IoT Edge Smoke Test Script
# Requires jq and azure cli with iot extension - https://docs.microsoft.com/en-us/azure/iot-hub/iot-hub-device-management-iot-extension-azure-cli-2-0

inputs=$#
iothub_name=$1
device_tag_value=$2
deployment_name=${3,,}

shift 3

while getopts ":d:r:t:s" opt; 
do
	case $opt in
	d)
	  d=$OPTARG
	  ;;
	r)
	  r=$OPTARG
	  ;;
	s)
	  s="true"
	  ;;
	t)
	  t=$OPTARG
	  ;;

	\?)
	  echo "Invalid option: -$OPTARG" >&2
	  exit 1
	  ;;
	:)
	  echo "Option -$OPTARG requires an argument." >&2
	  exit 1
	  ;;
	esac
done
shift $((OPTIND-1))

delayInSeconds=${d:=3}
numberOfRetries=${r:=60}
singleDeviceTest=${s:="false"}
device_tag=${t:="environment"}

usage(){
    echo "***Azure IoT Edge Smoke Test Script***"
    echo "Usage: ./edgeSmokeTest.sh <iothub.name> <device_tag_value> <deployment_name>"
    echo "<device_tag_value> is the value of the device_tag to determine which devices to target."
    echo "<deployment_name> is the iot deployment name to test. i.e. az iot edge deployment create --config-id <deployment_name>"
    echo "---Optional Parameters--- "
    echo "-d    :delay in seconds until re-poll module twin. Default is 3 seconds"
    echo "-r    :number of retries. Default is 60"
    echo "-s    :using this switch enables single device test otherwise defaults to test all devices matching the value of the device_tag. Pass the single deviceId to <device_tag_value> with this switch enabled."
    echo "-t    :device_tag used to query for which IoT Edge devices to find.  If not specified, a tag called environment will be used."

}

startTest(){

az_iot_ext_install_status=$(az extension show --name azure-iot)
az_iot_ext_install_status_len=${#az_iot_ext_install_status}

if [ $az_iot_ext_install_status_len -eq 0 ]
then
    az extension add --name azure-iot
fi

if [[ $singleDeviceTest != "false" ]]
then
  devices=($device_tag_value)
  echo "Testing a single device with deviceId $device_tag_value"
  deviceExists=$(az iot hub device-identity show -n $iothub_name -d $device_tag_value)
  if [ ! $? == 0 ]; then
    echo "An IoT Edge device twin with deviceId $device_tag_value cannot be found."
    exit 1
  fi
  device_tag="deviceId"
else
  devices=($(az iot hub query --hub-name $iothub_name --query-command "SELECT * FROM devices WHERE tags.$device_tag = '$device_tag_value'" --query '[].deviceId' -o tsv)) 
  if [ ${#devices[*]} -eq 0 ]
  then
          echo "No devices with tag $device_tag of value $device_tag_value found in $iothub_name"
          return 1
  else
          echo "Number of devices with tag $device_tag of value $device_tag_value found in $iothub_name: ${#devices[*]}"
  fi
fi

validateDevicesConnectedToIoTHub
validateDevicesAppliedDeployment
validateDevicesModulesRunning

}

validateDevicesConnectedToIoTHub(){
echo "Validating devices where $device_tag = $device_tag_value are currently connected to the iot hub..."
for device in ${devices[*]}
do
        pingStatus=unknown
		for ((i=1;i<=numberOfRetries;i++)); 
		do
			if [[ $pingStatus != "200" ]]
			then
					pingStatus=($(az iot hub invoke-module-method --method-name 'ping' --module-id '$edgeAgent' --hub-name $iothub_name --device-id $device --query 'status' -o tsv))
					echo 'device' $device 'ping status: ' $pingStatus
					sleep $delayInSeconds
			fi
		done
    if [[ $pingStatus != "200" ]]
    then 
        echo $device 'is not connected with ping status' $pingStatus 'exiting.' 1>&2; exit 1;
    fi
done
}

validateDevicesAppliedDeployment(){
echo "Validating devices where $device_tag = $device_tag_value have applied the $deployment_name deployment..."
for device in ${devices[*]}
do
        deploymentStatus=unknown
		for ((i=1;i<=numberOfRetries;i++)); 
		do
			if [[ $deploymentStatus != "Applied" ]]
			then
					deploymentStatus=($(az iot hub module-twin show --module-id '$edgeAgent' --hub-name $iothub_name --device-id $device --query 'configurations.["'"$deployment_name"'"][0].status' -o tsv))
					echo 'device' $device 'deployment status:' $deploymentStatus
					sleep $delayInSeconds
			fi
		done
    if [[ $deploymentStatus != "Applied" ]]
    then 
      echo 'device' $device 'deployment status:' $deploymentStatus 'is not applied. Exiting.' 1>&2; exit 1;
    fi
done
}

validateDevicesModulesRunning(){
echo "Validating devices where $device_tag = $device_tag_value configured modules are running..."
for device in ${devices[*]}
do
  edgeAgentTwin=$(az iot hub module-twin show --module-id '$edgeAgent' --hub-name $iothub_name --device-id $device)
  deviceModules=($(echo $edgeAgentTwin | jq -r .properties.desired.modules | jq -r to_entries[].key))
  echo "Number of modules configured for $device: ${#deviceModules[*]}"

  for deviceModule in ${deviceModules[*]}
  do
    moduleStatus=unknown
    for ((i=1;i<=numberOfRetries;i++)); 
    do
      if [[ $moduleStatus != "running" ]]
      then
          moduleStatus=$(echo $edgeAgentTwin | jq -r .properties.reported.modules[\"$deviceModule\"].runtimeStatus)
          echo 'device' $device 'module' $deviceModule 'status' $moduleStatus
          
          if [[ $moduleStatus != "running" ]]
          then
            sleep $delayInSeconds
            edgeAgentTwin=$(az iot hub module-twin show --module-id '$edgeAgent' --hub-name $iothub_name --device-id $device)
          fi
      fi
    done
    if [[ $moduleStatus != "running" ]]
    then 
      echo 'device' $device 'module' $deviceModule 'status' $moduleStatus 'is not running. Exiting.' 1>&2; exit 1;
    fi
  done
done
}

# Check Arguments
[[ $inputs < 3 ]] && { usage && exit 1; } || startTest
