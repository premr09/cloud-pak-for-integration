#!/bin/bash

export cluster_name=$1
export domain_name=$2
export openshift_user=$3
export openshift_password=$4
export namespace=$5
export qm_name=$6
export qm_type=$7
export tracing_flag=$8
export web_console_flag=$9

release_name="icp-mq"
qm_name="QM-CP4I"
qm_type="SingleInstance"
tracing_flag=false
web_console_flag=true

echo "Logging to Openshift - https://api.${cluster_name}.${domain_name}:6443 .."
var=0
oc login "https://api.${cluster_name}.${domain_name}:6443" -u "$openshift_user" -p "$openshift_password" --insecure-skip-tls-verify=true
var=$?
echo "exit code: $var"

echo "Installing MQ in ${namespace} .."
echo "Tracing is currently set to false"

cat << EOF | oc apply -f -
apiVersion: mq.ibm.com/v1beta1
kind: QueueManager
metadata:
  name: ${release_name}
  namespace: ${namespace}
spec:
  license:
    accept: true
    license: L-RJON-BN7PN3
    use: NonProduction
  queueManager:
    name: ${qm_name}
    storage:
      queueManager:
        type: ephemeral
    availability:
      type: ${qm_type}
  template:
    pod:
      containers:
        - env:
            - name: MQSNOAUT
              value: 'yes'
          name: qmgr
  version: 9.2.0.0-r1
  web:
    enabled: ${web_console_flag}
  tracing:
    enabled: ${tracing_flag}
    namespace: ${namespace}
EOF

echo "Validating MQ installation.."
mq=0

while [[ mq -eq 0 ]]; do
	oc get pods -n ${namespace} | grep ${release_name} | grep Running | grep 1/1
	resp=$?
	if [[ resp -ne 0 ]]; then
		echo -e "No running pods found for ${release_name} Waiting.."
		sleep 60
	else
		mq=1;
	fi
done

echo "Installation completed: Queue Namager Name: ${qm_name}, Queue Manager Type: ${qm_type}"
if [[ "$web_console_flag" == "true" ]]; then
	echo "MQ Web Console URL: https://${release_name}-ibm-mq-web-${namespace}.apps.${cluster_name}.${domain_name}/ibmmq/console/"
fi
