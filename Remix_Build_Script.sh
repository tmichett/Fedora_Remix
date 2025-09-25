#!/usr/bin/bash
#
# Travis Michette <tmichett@redhat.com>

## Script used to create LiveISO for the FedoraRemix based on the KS

setenforce 0

# Use script to capture output with colors
script -c "livecd-creator --cache=/livecd-creator/package-cache -f FedoraRemix -c FedoraRemix.ks --title=\"Travis's Fedora Remix 42\" 2>&1" FedoraBuild-$(date +%m%d%y-%k%M).out

