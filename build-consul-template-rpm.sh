#!/bin/bash
#

set -e

if [[ -z "$1" ]]; then
  echo $"Usage: $0 <VERSION> [ARCH]"
  exit 1
fi

NAME=consul-template
VERSION=$1

if [[ -z "$2" ]]; then
  ARCH=`uname -m`
else
  ARCH=$2
fi
#https://github.com/hashicorp/consul-template/releases/download/v0.2.0/consul-template_0.2.0_linux_amd64.tar.gz
case "${ARCH}" in
    i386)
        ZIP=${NAME}_${VERSION}_linux_386.zip
        ;;
    x86_64)
       ZIP=${NAME}_${VERSION}_linux_amd64.zip
        ;;
    *)
        echo $"Unknown architecture ${ARCH}" >&2
        exit 1
        ;;
esac

URL="https://releases.hashicorp.com/${NAME}/${VERSION}/${ZIP}"
echo $"Creating ${NAME} RPM build file version ${VERSION}"

# fetching consul
curl -k -L -o $ZIP $URL || {
    echo $"URL or version not found!" >&2
    exit 1
}

# clear target foler
rm -rf consul-templates/target/*

# create target structure
mkdir -p consul-templates/target/usr/local/bin/
cp -r sources/${NAME}/etc/ consul-templates/target/

# unzip
#tar -xf ${ZIP} -O > consul-templates/target/usr/local/bin/${NAME}
unzip -qq ${ZIP} -d consul-templates/target/usr/local/bin/

rm ${ZIP}

# create rpm
fpm -s dir -t rpm -f \
       -C consul-templates/target -n ${NAME} \
       -v ${VERSION} \
       -p consul-templates/target/consul-template.rpm \
       -d "consul" \
       --after-install spec/template_install.spec \
       --after-remove spec/template_uninstall.spec \
       --rpm-ignore-iteration-in-dependencies \
       --description "Consul-template RPM package for RedHat Enterprise Linux 6" \
       --url "https://github.com/hypoport/consul-rpm-rhel6" \
       usr/ etc/

rm -rf consul-templates/target/etc consul-templates/target/usr
