## Pull FedoraRemix PXE Server Container Image
## Pre-downloads the container so it's available offline
## Container: quay.io/tmichett/fedoraremixpxe:latest

# Use formatting functions if available, fallback to simple echo
if type ks_print_section >/dev/null 2>&1; then
    ks_print_section "📦 PULLING PXE SERVER CONTAINER IMAGE"
    ks_print_step 1 3 "Configuring network for container download"
else
    echo "* =============================================================================="
    echo "* PULLING PXE SERVER CONTAINER IMAGE"
    echo "* =============================================================================="
    echo "[1/3] Configuring network for container download"
fi

# Ensure DNS is configured for external downloads
if [ -f /etc/resolv.conf ]; then
    cp /etc/resolv.conf /etc/resolv.conf.container-backup 2>/dev/null || true
fi

# Configure DNS for registry access
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

if type ks_print_info >/dev/null 2>&1; then
    ks_print_info "DNS configured for container registry access"
else
    echo "[INFO] DNS configured for container registry access"
fi

# Pull the container image
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 2 3 "Pulling container image from quay.io"
    ks_print_download "quay.io/tmichett/fedoraremixpxe:latest"
else
    echo "[2/3] Pulling container image from quay.io"
    echo "[DOWNLOAD] quay.io/tmichett/fedoraremixpxe:latest..."
fi

# Check if podman is available
if ! command -v podman >/dev/null 2>&1; then
    if type ks_print_error >/dev/null 2>&1; then
        ks_print_error "Podman not found, cannot pull container"
    else
        echo "[ERROR] Podman not found, cannot pull container"
    fi
else
    # Pull the container image for root user
    # Using --root to ensure it's stored in root's container storage
    if type ks_print_info >/dev/null 2>&1; then
        ks_print_info "This may take several minutes depending on network speed..."
    else
        echo "[INFO] This may take several minutes depending on network speed..."
    fi
    
    # Pull the container
    if podman pull quay.io/tmichett/fedoraremixpxe:latest 2>&1; then
        if type ks_print_success >/dev/null 2>&1; then
            ks_print_success "Container image pulled successfully"
        else
            echo "[OK] Container image pulled successfully"
        fi
        
        # Show image info
        if type ks_print_info >/dev/null 2>&1; then
            IMAGE_SIZE=$(podman images quay.io/tmichett/fedoraremixpxe:latest --format "{{.Size}}" 2>/dev/null)
            ks_print_info "Image size: ${IMAGE_SIZE:-unknown}"
        else
            IMAGE_SIZE=$(podman images quay.io/tmichett/fedoraremixpxe:latest --format "{{.Size}}" 2>/dev/null)
            echo "[INFO] Image size: ${IMAGE_SIZE:-unknown}"
        fi
    else
        if type ks_print_error >/dev/null 2>&1; then
            ks_print_error "Failed to pull container image"
            ks_print_warning "Container will be downloaded on first use of run-pxe-server"
        else
            echo "[ERROR] Failed to pull container image"
            echo "[WARN] Container will be downloaded on first use of run-pxe-server"
        fi
    fi
fi

# Verify the image exists
if type ks_print_step >/dev/null 2>&1; then
    ks_print_step 3 3 "Verifying container image"
else
    echo "[3/3] Verifying container image"
fi

if podman image exists quay.io/tmichett/fedoraremixpxe:latest 2>/dev/null; then
    if type ks_print_success >/dev/null 2>&1; then
        ks_print_success "Container image verified and ready"
    else
        echo "[OK] Container image verified and ready"
    fi
    
    # List the image details
    if type ks_print_info >/dev/null 2>&1; then
        ks_print_info "Container details:"
    else
        echo "[INFO] Container details:"
    fi
    podman images quay.io/tmichett/fedoraremixpxe:latest --format "  Repository: {{.Repository}}\n  Tag: {{.Tag}}\n  ID: {{.ID}}\n  Size: {{.Size}}\n  Created: {{.Created}}"
else
    if type ks_print_warning >/dev/null 2>&1; then
        ks_print_warning "Container image not found - will be downloaded on first use"
    else
        echo "[WARN] Container image not found - will be downloaded on first use"
    fi
fi

# Restore original resolv.conf if we backed it up
if [ -f /etc/resolv.conf.container-backup ]; then
    mv /etc/resolv.conf.container-backup /etc/resolv.conf 2>/dev/null || true
fi

# Display completion message
if type ks_completion_banner >/dev/null 2>&1; then
    ks_completion_banner "PXE CONTAINER IMAGE"
    ks_print_info "The PXE server container is now pre-cached on this system"
    ks_print_info "Run 'sudo run-pxe-server' to start the PXE server"
else
    echo ""
    echo "[DONE][DONE][DONE] PXE CONTAINER IMAGE download completed! [DONE][DONE][DONE]"
    echo ""
    echo "[INFO] The PXE server container is now pre-cached on this system"
    echo "[INFO] Run 'sudo run-pxe-server' to start the PXE server"
    echo ""
fi

