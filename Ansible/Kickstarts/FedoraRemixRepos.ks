# Extra Repos
repo --name="google-chrome" --baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
repo --name="vscode" --baseurl=https://packages.microsoft.com/yumrepos/vscode
repo --name="rpmfusionnon-free" --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-$releasever&arch=$basearch
repo --name="rpmfusionnon-nonfree" --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-$releasever&arch=$basearch
repo --name="GithubCLITools" --baseurl=https://cli.github.com/packages/rpm
repo --name="DUST-COPR" --baseurl=https://download.copr.fedorainfracloud.org/results/gourlaysama/dust/fedora-$releasever-$basearch/
repo --name="YAZI-COPR" --baseurl=https://download.copr.fedorainfracloud.org/results/lihaohong/yazi/fedora-$releasever-$basearch/
repo --name="EZA-COPR" --baseurl=https://download.copr.fedorainfracloud.org/results/alternateved/eza/fedora-$releasever-$basearch/

