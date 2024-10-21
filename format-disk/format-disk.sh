#!/usr/bin/env bash

# FORMATING DISK
sudo fdisk /dev/sda << EOF
g
n


+1000M
t
1
n


+4000M
t

19
n



w
EOF 




