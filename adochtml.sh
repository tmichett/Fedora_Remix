#!/usr/bin/bash
#
# Travis Michette <tmichett@redhat.com>

set -e

container='quay.io/tmichett/adoc-html:latest'
current_directory="$(pwd)"


echo "Command being run is: podman run --name adochtml --rm -v $current_directory:/tmp/coursebook:Z $container  $1"

podman run --name adochtml --rm -v $current_directory:/tmp/ADOC_Work:Z $container $1
