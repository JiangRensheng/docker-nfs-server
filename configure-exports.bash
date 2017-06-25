#!/bin/bash
NFS_EXPORT_DIRS=$(compgen -A variable|grep NFS_EXPORT_DIR)
echo 'configure-exports called!'
for dir in $NFS_EXPORT_DIRS
do

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

