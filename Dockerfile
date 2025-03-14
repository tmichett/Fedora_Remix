FROM registry.fedoraproject.org/fedora:34-x86_64

MAINTAINER Travis Michette <tmichett@redhat.com>

# --version option and argument for gem install
# Now it is the RPM package version
#ARG ASCIIDOCTOR=
#ARG ASCIIDOCTOR="-2.0.10"

ENV ADOC_Files="/tmp/ADOC_Work"

RUN dnf -y install  ruby python3 asciidoc \
  && dnf clean all \
  && gem install asciidoctor rouge  pygments.rb coderay \
  && mkdir -p ${ADOC_Files} \
  && mkdir -p /opt/asciidoc

ADD asciidoc /opt

VOLUME ${ADOC_Files}

WORKDIR ${ADOC_Files}
 
ENTRYPOINT [ "/usr/local/share/gems/gems/asciidoctor-2.0.17/bin/asciidoctor"]


