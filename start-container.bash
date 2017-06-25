#!/bin/bash

is_process_running() {
 if [[ -n $(pgrep $1) ]]; 
 then
  return 0
 else
  return 1
 fi
}

umount_all_exports() {
  awk '{print $1}' /etc/exports | xargs -i umount {} 2>&1 >/dev/null
}

stop_container() {
 echo 'received SIGTERM'
 /usr/sbin/rpc.nfsd 0
 umount_all_exports
 sleep 1
 exit
}

trap stop_container SIGTERM


nfs_config_monitor() {

  NFS_EXPORT_DIRS=$(compgen -A variable|grep NFS_EXPORT_DIR)
  for dir in $NFS_EXPORT_DIRS; do

    index=${dir##*_}

    net=NFS_EXPORT_DOMAIN_$index
    opt=NFS_EXPORT_OPTIONS_$index

    if [[ -n ${!dir} ]] && [[ -n ${!net} ]] && [[ -n ${!opt} ]] ; then
      export_dir="${!dir}"
      if [ x"$(ls ${!dir} -l | awk '{print $4}')" == x"disk" ]; then
        folder="$(basename ${!dir})"
        export_dir="/mnt/${folder}"
        [ -d "${export_dir}" ] || mkdir "${export_dir}"
        mount "${!dir}" "${export_dir}"
        echo ${export_dir} ${!net}'('${!opt}')'
      else
        echo ${!dir} ${!net}'('${!opt}')'
      fi
    fi
  done>/etc/exports

}

nfs_server_monitor() {

 if ! is_process_running 'rpcbind'; then
  echo 'starting rpcbind'
  /sbin/rpcbind -i
 fi

 if ! is_process_running 'rpc.statd'; then
  echo 'starting rpc.statd'
  /usr/sbin/rpc.statd --no-notify --port 32765 --outgoing-port 32766
  sleep .5
 fi

 if [[ ! -a /proc/fs/nfsd/threads ]]; then
  echo 'starting rpc.nfsd'
  echo $(pgrep 'nfsd')
  /usr/sbin/rpc.nfsd -V3 -N2 -N4 -d 8
 fi

 if ! is_process_running 'rpc.mountd'; then
  echo 'starting rpc.mountd'
  /usr/sbin/rpc.mountd -V3 -N2 -N4 --port 32767
  /usr/sbin/exportfs -ra
 fi

}



while :
do

  old_md5="$(md5sum /etc/exports)"
  nfs_config_monitor
  new_md5="$(md5sum /etc/exports)"

  if [ x"${old_md5}" = x"${new_md5}" ]; then
    nfs_server_monitor
  else
    break
  fi

  sleep 5

done


