
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

Any questions with any of this, please reach out to [mailto:technical-operations@systeminit.com]technical-operations@systeminit.com or in Slack.

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
- The system configuration sets up a cron in /etc/cron.daily and an application folder within /etc/si-device-compliance/ which will:
  - Query the system for various properties, including properties:
    - Hardware indetifiers/signatures such as:
        - lscpu 
        - lshwinfo
        - dmidecode -t bios
    - Status of disks:
        - Name
        - Encryption Status
    - Users on the host
    - Screenlock Policy
      - Whether a password is required on screenlock
      - Timeout before screenlock
    - Whether there is an antivirus installed & active (such as [Clam AV]https://www.clamav.net/)
- Assemble a JSON payload and submit that information to the centralised compliance platform. 
- Delete the `/tmp/si-device-compliance/<RANDOM NUMBER>` installation directory

NB: A record of each submission can be found in /etc/si-device-complaince/records/

The properties files allow the installation to be configured to execute in one of two ways:

Specify the intent of the install e.g. dry-run or execute (Appendix 1) `/tmp/installation.vars`

Please review Appendix 1 to construct these supporting files for the installation, they can be re-used upon every installation.

Once theis file are available on the indetended install host/machine, run:
```
curl https://raw.githubusercontent.com/systeminit/si-device-compliance/feat/add-linux-device-compliance/orchestrate-install.sh > /tmp/orchestrate-install.sh
chmod a+x /tmp/orchestrate-install.sh
/bin/bash /tmp/orchestrate-install.sh /tmp/installation.vars
```

Once the installation is complete, the system should be reporting into the chosen compliance platform. 


<hr/>

## Appendicies

### Appendix 1: Installation Variables
This section explains how to construct a properties file which dictates how the system configuration acts during the install.

An example of this, along with an explanation of each of the properties is shown below:

*  `CONFIGURATION_MANAGEMENT_TOOL`: Currently only ansible is supported, others may come in future versions
*  `CONFIGURATION_MANAGEMENT_REPO`: The configuration management repository name
*  `CONFIGURATION_MANAGEMENT_BRANCH`: The branch name or commit of the installation instructions (`main` being the most up to date)
*  `INTENT`: One of [dry-run | execute]
*  `EMAIL_ADDRESS`: The corporate email address of the user responsible for the device
*  `SUBMISSION_TOKEN`: The submission token from 1Password to permit the user to submit device information, search COMPLIANCE_SUBMISSION_TOKEN in 1Password to find it.

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

<hr/>
