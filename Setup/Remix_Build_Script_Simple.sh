#!/usr/bin/bash
#
# Travis Michette <tmichett@redhat.com>
# Alternative version using tee instead of script command

## Script used to create LiveISO for the FedoraRemix based on the KS

setenforce 0

# Use tee to capture output (simpler alternative to script command)
livecd-creator --cache=/livecd-creator/package-cache -f FedoraRemix -c FedoraRemix.ks --title="Travis's Fedora Remix 42" 2>&1 | tee FedoraBuild-$(date +%m%d%y-%k%M).out
