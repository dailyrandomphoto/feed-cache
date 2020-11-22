WORK_DIR=$(pwd)
mkdir -p temp && cd temp

echo Start fetch ...
while read path url ; do
    if [[ ! -z $path ]] && [[ ! -z $url ]]; then
      mkdir -p $(dirname $path)
      echo curl -o $path "${url}"
      curl -o $path "${url}"
    fi
done < ../fetch-list.txt
echo Done!

/usr/bin/rsync  -av --checksum --progress . $WORK_DIR
cd $WORK_DIR && rm -rf temp
