#!/bin/bash
#

packer init .
packer fmt .
packer build centos.json.pkr.hcl
