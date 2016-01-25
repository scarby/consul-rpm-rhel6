#!/bin/bash
#

set -e
NAME='consul'

if [[ -z "$1" ]]; then
  echo $"Usage: $0 <VERSION> [ARCH]"
  exit 1
fi

VERSION=$1

if [[ -z "$2" ]]; then
  ARCH=`uname -m`
else
  ARCH=$2
fi

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

URL="https://releases.hashicorp.com/consul/${VERSION}/${ZIP}"
echo $"Creating consul ${ARCH} RPM build file version ${VERSION}"

# fetching consul
curl -k -L -o $ZIP $URL || {
    echo $"URL or version not found!" >&2
    exit 1
}

# clear target foler
rm -rf consul/target/*

# create target structure
mkdir -p consul/target/usr/local/bin
mkdir -p consul/target/etc/init.d
cp -r sources/consul/etc/ consul/target/

# unzip
unzip -qq ${ZIP} -d consul/target/usr/local/bin/
rm ${ZIP}

# create rpm
fpm -s dir -t rpm -f \
       -C consul/target \
       -n consul \
       -v ${VERSION} \
       -p consul/target \
       -a ${ARCH} \
       --rpm-ignore-iteration-in-dependencies \
       --after-install spec/service_install.spec \
       --after-remove spec/service_uninstall.spec \
       --description "Consul RPM package for RedHat Enterprise Linux 6" \
       --url "https://github.com/hypoport/consul-rpm-rhel6" \
       usr/ etc/

rm -rf consul/target/etc consul/target/usr
