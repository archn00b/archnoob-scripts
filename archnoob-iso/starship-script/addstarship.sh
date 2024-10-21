#!/usr/bin/env bash

# install starship
mkdir -p /tmp/archlive/airootfs/usr/fonts
cp -rf FiraCode /tmp/archlive/airootfs/usr/share/fonts/ 
[ -f ~/.bashrc ] && cp  ~/.bashrc ~/.bashrc.bak."$(date +"%Y%m%d_%H%M%S")"
[ -f ~/.bashrc ] && \
echo '
#including starship
eval "$(starship init bash)" ' >> /tmp/archlive/airootfs/etc/skel/.bashrc && source /tmp/archlive/airootfs/etc/skel/.bashrc




 
