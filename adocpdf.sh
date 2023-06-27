#!/usr/bin/bash
#
# Travis Michette <tmichett@redhat.com>

set -e

container='quay.io/tmichett/asciidocpdf:latest'
pdf_theme='-a pdf-theme=/opt/asciidoc/themes/tm-gls-redhat-theme.yml'
current_directory="$(pwd)"


echo "Command being run is: podman run --name adocpdf --rm -v $current_directory:/tmp/coursebook:Z $container $pdf_theme $1"

#podman run --name adocpdf --rm -v $current_directory:/tmp/coursebook:Z $container $pdf_theme $1


podman run --name adocpdf --rm -v $current_directory:/tmp/coursebook:Z  -e "pdf_theme=${pdf_theme}" -e "book_name=${1}" $container
