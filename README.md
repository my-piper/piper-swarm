# DevOps 

## Setup

### SeaweedFS

from `weed shell` execute:
```shell
fs.configure -locationPrefix=/buckets/artefacts/ -ttl=2w -volumeGrowthCount=1 -replication=000 -apply
fs.configure -locationPrefix=/buckets/assets/ -ttl=6M -volumeGrowthCount=1 -replication=000 -apply
fs.configure -locationPrefix=/buckets/outputs/ -ttl=4w -volumeGrowthCount=1 -replication=000 -apply

s3.configure -user=anonymous -actions=Read:artefacts,Read:outputs,Read:assets -apply
s3.configure -access_key=${S3_ACCESS_KEY} -secret_key=${S3_SECRET_KEY} -user=piper -actions=Read,Write:artefacts,Read,Write:outputs,Read,Write:assets -apply
```


## Load configs

```shell
mkdir /opt/piper
mkdir /opt/piper/devops
cd /opt/piper
git config --global credential.helper store
git clone https://gitlab.com/generative-core/piper/devops/platform.git ./devops
```

## Run system

```bash
make up
make status
```

## Docker

```shell
docker node update --label-add piper-worker=true production-2
docker node update --label-add piper-chrome=true piper-next-3
docker node update --label-rm app development 
```
