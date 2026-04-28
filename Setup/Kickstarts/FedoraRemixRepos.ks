# Extra Repos
# RPM Fusion: use official metalink — static download1.rpmfusion.org .../releases/N/Everything/... paths
# often 404 (mirrors move); metalink resolves current mirror URLs per release/arch.
repo --name="rpmfusion-free" --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-$releasever&arch=$basearch
repo --name="rpmfusion-nonfree" --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-$releasever&arch=$basearch
repo --name="google-chrome" --baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
repo --name="vscode" --baseurl=https://packages.microsoft.com/yumrepos/vscode
repo --name="GithubCLITools" --baseurl=https://cli.github.com/packages/rpm
repo --name="DUST-COPR" --baseurl=https://download.copr.fedorainfracloud.org/results/gourlaysama/dust/fedora-$releasever-$basearch/
repo --name="YAZI-COPR" --baseurl=https://download.copr.fedorainfracloud.org/results/lihaohong/yazi/fedora-$releasever-$basearch/
# eza: ship from Fedora rust-eza (do not use alternateved/eza COPR — no F41 chroot; repodata 404).
repo --name="FedoraRemix-COPR" --baseurl=https://download.copr.fedorainfracloud.org/results/tmichett/FedoraRemix/fedora-$releasever-$basearch/ --install --cost=100

