#!/usr/bin/bash
#
# Travis Michette <tmichett@redhat.com>

## Script used to create LiveISO for the FedoraRemix based on the KS

setenforce 0

livecd-creator --cache=/livecd-creator/package-cache -f FedoraRemix -c FedoraRemix.ks --title="Travis's Fedora Remix" 2>&1 | tee FedoraBuildi-$(date +%m%d%y-%k%M).out

