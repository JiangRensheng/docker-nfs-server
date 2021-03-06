#!/bin/bash

export_dir=$1

docker run \
  -it \
  --rm \
  --privileged \
  --name nfs-server \
  -e NFS_EXPORT_DIR_1=${export_dir} \
  -e NFS_EXPORT_DOMAIN_1=\* \
  -e NFS_EXPORT_OPTIONS_1=ro,insecure,no_subtree_check,no_root_squash,fsid=1 \
  -p 111:111 -p 111:111/udp \
  -p 2049:2049 \
  -p 2049:2049/udp \
  -p 32765:32765 \
  -p 32765:32765/udp \
  -p 32766:32766 \
  -p 32766:32766/udp \
  -p 32767:32767 \
  -p 32767:32767/udp \
  --entrypoint /bin/bash \
  deepsecs.com/nfs-server:arm64
