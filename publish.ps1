$VER=$args[0] # || $1

if(-not $VER){
    $VER='dev'    
}

docker build --build-arg "BASE_IMG_TAG=$VER" -t "jijiechen-docker.pkg.coding.net/sharpcr/apps/sharpcr-registry-syncer:$VER" .
docker push "jijiechen-docker.pkg.coding.net/sharpcr/apps/sharpcr-registry-syncer:$VER"