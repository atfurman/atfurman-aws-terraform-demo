# Overview
This document provides an overview and instructions to set up and use [Ansible](https://docs.ansible.com/) to configure the demo web server deployed using terraform.

This automation is written to work in the context of this demo project specifically, though it can be relatively easily ported to other contexts if desired.

# Using this solution

This solution is dependent upon resources deployed using terraform, but is not directly invoked as part of that automation. Once the required resources are in place, this automation is meant to be run as a manual step.

# Prerequisites
- Python 3 >= 3.12 (earlier versions may work but are untested)
- Linux/Mac/WSL. Use Windows at your own risk
- AWS CLI authenticated. Default profile is presumed, though this can be adjusted if desired.

# Setup
All commands documented here presume you are operating from the same directory as this readme.

## Create virtual environment and install ansible and dependencies

A [python virtual environment](https://docs.python.org/3/library/venv.html) is used to install dependencies. All further documentation presumes use of this virtual environment.

```bash
python3 -m venv .venv
```

```bash
source .venv/bin/activate
```

```bash
pip install --upgrade pip
pip install -r requirements/requirements.txt
```


