# Install Docker

```bash
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce
sudo docker run hello-world
docker swarm init

## Load configs

```bash
mkdir /opt/piper
mkdir /opt/piper/devops
cd /opt/piper
git config --global credential.helper store
git clone https://gitlab.com/generative-core/piper/devops/platform.git ./devops
```

# Run system

```bash
make up
make status
```
