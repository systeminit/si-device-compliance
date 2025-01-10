# System Initiative Device Compliance
## Onboarding New Machine Quick Guide:

Ensure your system has `git`, `jq`. `lscpu`, `lshw` and `ansible-playbook` packages available to your user.

Pull the Orchestration File & example vars file
```
curl https://raw.githubusercontent.com/systeminit/si-device-compliance/main/orchestrate-install.sh > /tmp/orchestrate-install.sh
curl https://raw.githubusercontent.com/systeminit/si-device-compliance/main/installation.vars > /tmp/installation.vars
```

Make the script executable
```
chmod a+x /tmp/orchestrate-install.sh 
```

Adjust the variables file for your user/machine values
```
vim /tmp/installation.vars
```
Modify these fields to their correct value:
```
EMAIL_ADDRESS: [email_id]                     # Your corporate systeminit.com email id
SUBMISSION_TOKEN: [submission_token]          # Your submission token # Appendix 2 - Generating a Submission Token
ROOT_DISK_ENCRYPTED_PARTITION_BLK: [disk-id]  # Your encrypted OS root disk blk
USING_PASSWORD_MANAGER: [true/false]          # Whether you are using a password manager
```

Run the installation:
```
/bin/bash /tmp/orchestrate-install.sh /tmp/installation.vars
```

You can check it is submitting correctly with:
```
sudo /etc/si-device-compliance/collect_compliance_data.sh <your token>
```

## System Initiative Device Compliance Background

Devices that fall out of the functionality of other compliance tooling can leverage this repository tooling to submit compliance information from any device. Currently only Linux devices are supported, but we could develop it out into an agent that supports other architectures/devices if we wished.

The intended list of currently supported Linux Distributions are:
* Ubuntu (all supported versions)

The system configuration is written in such a way that the following (or any other) distribution of Linux should be able to be supported with minor adjustments if any, it's just untested:
* Debian (untested)
* Fedora (untested)
* Arch Linux (untested)
* Linux Mint (untested)
* openSUSE (untested)
* Gentoo (untested)
* Manjaro (untested)

Any questions with any of this, please reach out to [technical-operations@systeminit.com](mailto:technical-operations@systeminit.com) or reach out in Slack to john@systeminit.com.

<br/>

## What is in this repository?

This repository holds the information and tasks required to create a Compliant System Initiative System. Ansible is used to assert the configuration however any other system configuration methodology or tool can be used (including manually provisioning), if the tasks achieve the same outcome.

<br/>

## Who Uses this repository?

System Initiative Employees or Contractors needing to certify their devices to meet the security needs of the business

It is the user of the repository's responsibility to ensure:
- The tooling is working as expected on their host
- That each asserted facet of the system remains within compliance [See Information Security Policy]

<br/>

## How It Works & Usage
A remote orchestration script `orchestrate-install.sh` is pulled and then executed on the machine with two supporting property files using ansible. 

The workflow is as follows:
- Verify the host has the suitable packages on it for the reporting platform to work
- Verify that within installation.vars that the relevant configuration properties are set
- Pull the remainder of the system configuration from the specified git repository in the installation.vars
- Execute the system configuration on the host from a new folder in `/tmp/si-device-compliance/<RANDOM NUMBER>` to facilitate the install
- The system configuration sets up a service file and timer, clamav and an application folder within /etc/si-device-compliance/ which will:
  - Query the system for various properties, including properties:
    - Hardware indetifiers/signatures such as:
        - lscpu 
        - lshwinfo
        - dmidecode -t bios
    - Status of root OS disk:
        - Name
        - Encryption Status
    - Screenlock Policy
      - Whether a password is required on screenlock
      - Timeout before screenlock
    - Whether there is an antivirus installed & active (such as [Clam AV]https://www.clamav.net/)
- Assemble a JSON payload and submit that information to the centralised compliance platform. 
- Delete the `/tmp/si-device-compliance/<RANDOM NUMBER>` installation directory

NB: A record of each submission can be found in /etc/si-device-compliance/records/

Please review Appendix 1 to construct these supporting files for the installation, they can be re-used upon every installation.

Once these files are available on the intended install host/machine, run:
```
curl https://raw.githubusercontent.com/systeminit/si-device-compliance/feat/add-linux-device-compliance/orchestrate-install.sh > /tmp/orchestrate-install.sh
chmod a+x /tmp/orchestrate-install.sh
/bin/bash /tmp/orchestrate-install.sh /tmp/installation.vars
```

Once the installation is complete, the system should be reporting into the chosen compliance platform. 

You can check it's working by one-off firing the data submission via a call like:
sudo /etc/si-device-compliance/collect_compliance_data.sh SUBMISSION_TOKEN 

<hr/>

## Appendicies

### Appendix 1: Installation Variables
This section explains how to construct a properties file which dictates how the system configuration acts during the install.

An example of this, along with an explanation of each of the properties is shown below:

*  `CONFIGURATION_MANAGEMENT_TOOL`: Currently only ansible is supported, others may come in future versions
*  `CONFIGURATION_MANAGEMENT_REPO`: The configuration management repository name
*  `CONFIGURATION_MANAGEMENT_BRANCH`: The branch name or commit of the installation instructions (`main` being the most up to date)
*  `EMAIL_ADDRESS`: The corporate email address of the user responsible for the device
*  `SUBMISSION_TOKEN`: The submission token from SI to permit the user to submit device information

<br/>

An example of this in practice:
```
---
# --------------------------------------------------------------------
CONFIGURATION_MANAGEMENT_TOOL: ansible
CONFIGURATION_MANAGEMENT_REPO: https://github.com/systeminit/si-device-compliance.git
CONFIGURATION_MANAGEMENT_BRANCH: main
EMAIL_ADDRESS: john@systeminit.com
SUBMISSION_TOKEN: abc123abc123
# --------------------------------------------------------------------
```

### Appendix 2: Generating a Submission Token
To generate a submission token for your machine/user, navigate to the Technical Operations workspace here:
https://app.systeminit.com/w/01J7PP420PHW97TJJB5BA0SQ9A/head/c/01JH8A98RT2XF5XXYGQAD7EYG8/v/?s=c_01JH8AA327VZMMKM866FEPGGVR&t=attributes

Create a new changeset and add a new SSM parameter with the following content:
* *SI Name:* <firstname> <lastname> - Vanta Submission Token e.g. John Watson - Vanta Submission Token
* *Description:* Hardware submission token for si-device-compliance
* *ParameterName:* SUBMISSION_TOKEN_FIRSTNAME_LASTNAME e.g. SUBMISSION_TOKEN_JACOB_HELWIG
* *ParameterType:* String
* *ParameterValue:* A unique, locally generated 20 character alphanumeric password from `pwgen 20` or similar

And request apply. Once applied it will then automatically be accepted by the compliance platform when attempting to submit data for your device.

<hr/>
