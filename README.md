# DevOps 

## Setup

### SeaweedFS

from `weed shell` execute:
```shell
fs.configure -locationPrefix=/buckets/artefacts/ -ttl=1d -volumeGrowthCount=1 -replication=000 -apply
fs.configure -locationPrefix=/buckets/launches/ -ttl=14d -volumeGrowthCount=1 -replication=000 -apply
fs.configure -locationPrefix=/buckets/assets/ -volumeGrowthCount=1 -replication=000 -apply

s3.configure -user=anonymous -actions=Read:artefacts,Read:launches,Read:assets -apply
s3.configure -access_key=<> -secret_key=<> -user=piper -actions=Read,Write -apply
```


# Load configs

```shell
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

# TODO...

