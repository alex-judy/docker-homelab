#!/bin/bash
#Installs docker and docker compose, doppler (secrets management), and copies configured files to user's home directory.

function confirm() {
    while true; do
        read -r -p "Do you want to proceed? (YES/NO/CANCEL) " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            [Cc]* ) exit;;
            * ) echo "Please answer YES, NO, or CANCEL.";;
        esac
    done
}

echo "The following setup will configure environment variables. This should be run at initial setup unless you have already configured your environment variables."

if confirm; then
    read -r -p "Enter your Timezone: [America/New_York]" tz
    tz="${tz:-America/New_York}"
    echo "export TZ=$tz" >> ~/.bashrc

    read -r -p "Enter your PUID: " puid
    echo "export PUID=$puid" >> ~/.bashrc

    read -r -p "Enter your PGID: " pgid
    echo "export PUID=$pgid" >> ~/.bashrc

    read -r -p "Enter your Server IP: " serverIp
    echo "export SERVER_IP=$serverIp" >> ~/.bashrc

    read -r -p "Enter your DNS Resolver: [8.8.8.8]" dnsResolver
    dnsResolver="${dnsResolver:-8.8.8.8}"
    echo "export DNS_RESOLVER=$dnsResolver" >> ~/.bashrc

    read -r -p "Enter your Domain Name: " domainName
    echo "export DOMAIN_NAME=$domainName" >> ~/.bashrc

    read -r -p "Enter your Docker directory where you want to store all compose files, data, and configs: [/opt/docker-homelab]" dockerDir
    dockerDir="${dockerDir:-/opt/docker-homelab}"
    echo "export DOCKER_DIR=$dockerDir" >> ~/.bashrc

    read -r -p "Enter your media directory where you want to store all media files: [/mnt/media]" mediaDir
    mediaDir="${mediaDir:-/mnt/media}"
    echo "export MEDIA_DIR=$mediaDir" >> ~/.bashrc

    read -r -p "Enter your downloads directory where you want to store all downloaded content: [/mnt/downloads]" downloadsDir
    downloadsDir="${downloadsDir:-/mnt/downloads}"
    echo "export DOWNLOADS_DIR=$downloadsDir" >> ~/.bashrc
fi

echo "Installing Doppler..."
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo apt-key add -
echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list
sudo apt-get update && sudo apt-get install doppler

echo "Doppler version installed: $(doppler --version)"

echo "Updating doppler..."
doppler update

echo "Please login to your doppler account..."
doppler login

echo "Setting up doppler for $DOCKER_DIR..."
doppler setup --scope="$DOCKER_DIR"

echo "Updating system..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y ssh \
    wget \
    vim \
    tlp-rdw \
    intel-microcode \
    smartmontools \
    uidmap 

echo "Setting up SSH keys..."
mkdir ~/.ssh
ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N "" -C "FM-SRV"
touch ~/.ssh/authorized_keys

echo "Installing docker dependencies and services..."
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

echo "Setting up docker keyring and repository..."
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "Installing docker engine..."
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Verifying docker installation..."
sudo docker run hello-world

echo "Adding $USER to docker group..."
sudo usermod -aG docker "$USER"

docker compose version 

echo "Starting docker service..."
sudo service docker start

echo "Copying .bash_aliases to $HOME..."
sudo cp .bash_aliases "$HOME"
source ~/.bashrc

echo "New docker folder created at $DOCKER_DIR..."
sudo mkdir "$DOCKER_DIR"
sudo chgrp docker "$DOCKER_DIR"
sudo chmod g+rwX "$DOCKER_DIR"

echo "New bin folder created at $HOME/bin"
mkdir "$HOME/bin"

echo "Setting docker folder permissions..."
sudo chmod -R 775 "$DOCKER_DIR"

# Absolute paths are required when creating soft symlink
ln -s "$HOME"/src/homelab/compose-files "$DOCKER_DIR"

echo "Copying scripts to $HOME/bin"
cp -r scripts "$HOME/bin"

echo "Creating shared docker folder..."
mkdir "$DOCKER_DIR"/shared

echo "Creating traefik file/folder structure..."
mkdir "$DOCKER_DIR"/traefik
mkdir "$DOCKER_DIR"/traefik/acme
cp -r traefik/rules "$DOCKER_DIR"/traefik

touch "$DOCKER_DIR"/traefik/acme/acme.json
touch "$DOCKER_DIR"/traefik/logs/traefik.log
touch "$DOCKER_DIR"/traefik/logs/access.log

echo "Setting acme.json permissions..."
sudo chmod 600 "$DOCKER_DIR"/traefik/acme/acme.json

echo "Creating telegraf config..."
mkdir "$DOCKER_DIR"/configs/telegraf
touch "$DOCKER_DIR"/configs/telegraf/telegraf.conf

echo "Creating grafana directory..."
mkdir "$DOCKER_DIR"/data/grafana

echo "Creating docker networks..."
sudo docker network create --gateway 192.168.50.1 --subnet 192.168.50.0/24 traefik_proxy
sudo docker network create --gateway 192.168.100.1 --subnet 192.168.100.0/24 socket_proxy
sudo docker network create --gateway 192.168.150.1 --subnet 192.168.150.0/24 influxdb

sudo chown -R "$USER:$USER" /mnt
sudo chmod -R a=,a+rX,u+w,g+w /mnt

doppler run -- docker compose -f "$DOCKER_DIR"/compose-files/network/docker-compose.yml up -d --force-recreate 
doppler run -- docker compose -f "$DOCKER_DIR"/compose-files/bittor/docker-compose.yml up -d --force-recreate 
doppler run -- docker compose -f "$DOCKER_DIR"/compose-files/database/docker-compose.yml up -d --force-recreate 
doppler run -- docker compose -f "$DOCKER_DIR"/compose-files/indexers/docker-compose.yml up -d --force-recreate 
doppler run -- docker compose -f "$DOCKER_DIR"/compose-files/management/docker-compose.yml up -d --force-recreate 
doppler run -- docker compose -f "$DOCKER_DIR"/compose-files/monitoring/docker-compose.yml up -d --force-recreate 
doppler run -- docker compose -f "$DOCKER_DIR"/compose-files/media/docker-compose.yml up -d --force-recreate 
doppler run -- docker compose -f "$DOCKER_DIR"/compose-files/other/docker-compose.yml up -d --force-recreate 
doppler run -- docker compose -f "$DOCKER_DIR"/compose-files/pvr/docker-compose.yml up -d --force-recreate 
doppler run -- docker compose -f "$DOCKER_DIR"/compose-files/security/docker-compose.yml up -d --force-recreate 
doppler run -- docker compose -f "$DOCKER_DIR"/compose-files/utility/docker-compose.yml up -d --force-recreate
doppler run -- docker compose -f "$DOCKER_DIR"/compose-files/games/docker-compose.yml up -d --force-recreate

sudo chgrp docker "$DOCKER_DIR" -R
sudo chmod g+rwX "$DOCKER_DIR" -R