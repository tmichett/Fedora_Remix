%packages

# Exclude unwanted groups that fedora-live-base.ks pulls in
-@dial-up
-@input-methods
-@standard

# Install workstation-product-environment to resolve RhBug:1891500
#@^workstation-product-environment

# Exclude unwanted packages from @anaconda-tools group
# gfs2-utils may not exist in FC42, so we'll handle this more gracefully
-reiserfs-utils

%end
