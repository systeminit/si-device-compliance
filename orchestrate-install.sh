#!/bin/bash

# Call this function with: 
# ./orchestrate-install.sh <filepath to variables>

set -eo pipefail

VARIABLES_FILE="${1:-/tmp/installation.vars}"

# Get a value for a variable in order of preference (a) from the environment (b) from the variables file (c) using the default provided.
# this helps with running this script in pipelines
get_or_default() {
	VARIABLE_NAME=$1
	DEFAULT_VALUE=$2

	if [[ -v "$VARIABLE_NAME" ]]; then # it's defined as an environment variable
		echo "${!VARIABLE_NAME}"
		return 0
	fi

	if [[ $( grep --count --regexp "^${VARIABLE_NAME}:" "${VARIABLES_FILE}" ) == 1 ]]; then # it's defined in our variables file
		echo "$(sed --silent --expression "s%^${VARIABLE_NAME}: %%p" ${VARIABLES_FILE})"
		return 0
	fi
	
	# default value it is.
	echo "${DEFAULT_VALUE}"
	return 0
}

# check whether certain values have been defined - this is also where sensible default values can be kept
set_variables() {
    export CONFIGURATION_MANAGEMENT_BRANCH="$( get_or_default CONFIGURATION_MANAGEMENT_BRANCH main )"
    export CONFIGURATION_MANAGEMENT_REPO="$( get_or_default CONFIGURATION_MANAGEMENT_REPO https://github.com/systeminit/si-device-compliance.git )"
    export CONFIGURATION_MANAGEMENT_TOOL="$( get_or_default CONFIGURATION_MANAGEMENT_TOOL ansible )"
    export COMPLIANCE_DIR="$( get_or_default COMPLIANCE_DIR /etc/si-device-compliance )"
    export LOGS_DIR="$( get_or_default LOGS_DIR /etc/si-device-compliance/logs )"
}

check_free_disk_space(){
	
	echo "------------------------------------"
	echo "Checking free space for installation mount points"
	
	directory=$1
    space_required=$2

	# Check if mount point exists
	if [ -d "$directory" ]; then
		# Get size of mount point in gigabytes
		directory_size=$(df --block-size=G $directory | awk 'NR==2 {print $4}' | sed 's/G//')

		# Check if directory size is smaller than required size
		if [ "$directory_size" -lt $space_required ]; then
			echo "Error: $directory has less than $space_required of available space."
			exit 1
		fi
	fi

	echo "$directory mount point does have sufficient space."
	echo "---------------------------------"

}

check_params_set(){
	if [[ -z "$VARIABLES_FILE" ]]; then
		echo "Error: A variables file needs to be passed to this installation wrapper for it to succeed. Please invoke with ./orchestrate-install.sh <filepath>" 
		exit 1
	fi

    if [[ ! -s "$VARIABLES_FILE" ]]; then
		echo "Error: The specified file '$VARIABLES_FILE' does not exist or is not a regular file."
		exit 1
	fi

	echo "---------------------------------"
	echo "Values passed as inputs:"
	echo "VARIABLES_FILE=$VARIABLES_FILE"
	cat $VARIABLES_FILE
	echo "---------------------------------"
	return 0
}

check_system_release() {
	echo "------------------------------------"
	echo "/etc/os-release shown below:"
	cat /etc/os-release
	echo "System architecture: $( uname -a )"
	echo "------------------------------------"

	[[ "$(cat /etc/os-release | grep 'Ubuntu')" ]] && export OS_VARIANT="ubuntu" && return 0
    # More variants can be added in here
    
	echo "Unrecognised/unsupported OS variant - proceeding at your own risk"
	export OS_VARIANT="other" && return 0
}

check_pre_reqs() {
    echo "Checking prerequisites for $OS_VARIANT"
    if ! command -v git &>/dev/null; then
        echo "Error: git is not installed. Please install git and try again."
        exit 1
    fi
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is not installed. Please install jq and try again."
        exit 1
    fi
    if ! command -v lshw &>/dev/null; then
        echo "Error: lshw is not installed. Please install lshw and try again."
        exit 1
    fi
    if ! command -v lscpu &>/dev/null; then
        echo "Error: lscpu is not installed. Please install lscpu and try again."
        exit 1
    fi
	if [[ $CONFIGURATION_MANAGEMENT_TOOL == "ansible" ]]; then
		if ! command -v ansible-playbook &>/dev/null; then
			echo "Error: ansible-playbook is not installed. Please install Ansible and try again."
			echo "Info: https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html"
			exit 1
		fi
	# Handle other binaries for other systems here
	fi
    echo "All prerequisites are installed."
}

pull_configuration_management() {
	RANDOM_NUMBER=$RANDOM
	echo "Installation folder set to /tmp/si-device-compliance/$RANDOM_NUMBER"
	mkdir -p /tmp/si-device-compliance/$RANDOM_NUMBER && cd /tmp/si-device-compliance/$RANDOM_NUMBER
	git clone $CONFIGURATION_MANAGEMENT_REPO
	cd si-device-compliance
	echo "Checking out branch: $CONFIGURATION_MANAGEMENT_BRANCH"
	git checkout $CONFIGURATION_MANAGEMENT_BRANCH
	export SCRIPT_VERSION="$( get_or_default SCRIPT_VERSION $(git rev-parse --short HEAD) )"
}

execute_configuration_management() {
	if [[ $CONFIGURATION_MANAGEMENT_TOOL == "ansible" ]]; then
		ansible_location=$(whereis ansible | awk '{print $2}')
		ansible_playbook_location=$(whereis ansible-playbook | awk '{print $2}')
		echo "Info: Running config management against $($ansible_location --version | head -n 1)"
		$ansible_playbook_location -i ./compliance/ansible/hosts.yaml --connection=local ./compliance/ansible/main.yaml --extra-vars "@$VARIABLES_FILE" --extra-vars "SCRIPT_VERSION=$SCRIPT_VERSION"
		echo "Info: System Configuration should be correctly configured, please see logs in $LOGS_DIR/run.log to verify"
		#TODO(johnrwat): add much more detail here as to what happens next
	else
		echo "Error: Unsupported or unknown configuration management tool specified, exiting."
		exit 1
	fi
}

execute_cleanup() {
	rm -Rf /tmp/si-device-compliance*
}

check_params_set && echo -e "Installation Values found to be:\n - $VARIABLES_FILE"
check_system_release && echo "Operating System found to be $OS_VARIANT"
set_variables
check_free_disk_space "$COMPLIANCE_DIR" '5'
check_pre_reqs
pull_configuration_management
execute_configuration_management
execute_cleanup