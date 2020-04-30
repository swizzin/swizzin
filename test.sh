#!/bin/bash

#Purposefully broken to test syntax
distro=$(lsb_release -is)
codename=$(lsb_release -cs)

if [[ ! $codename =~ ("xenial") ]]; then

echo hi


