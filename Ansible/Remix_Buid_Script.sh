#!/usr/bin/bash
#
# Travis Michette <tmichett@redhat.com>

## Script used to create LiveISO for the FedoraRemix based on the KS

livecd-creator --cache=/livecd-creator/package-cache -f FedoraRemix -c FedoraRemix.ks --title="Travis's Fedora Remix" | tee FedoraBuildi-$(date +%m%d%y-%k%M).out

