# DevOps

## Setup

### SeaweedFS

from `weed shell` execute:

```shell
fs.configure -locationPrefix=/buckets/artefacts/ -ttl=2w -volumeGrowthCount=1 -replication=000 -apply
fs.configure -locationPrefix=/buckets/assets/ -ttl=6M -volumeGrowthCount=1 -replication=000 -apply
fs.configure -locationPrefix=/buckets/outputs/ -ttl=2w -volumeGrowthCount=1 -replication=000 -apply

s3.configure -user=anonymous -actions=Read:artefacts,Read:outputs,Read:assets -apply
s3.configure -access_key=${S3_ACCESS_KEY} -secret_key=${S3_SECRET_KEY} -user=piper -actions=Read:artefacts,Write:artefacts,Read:outputs,Write:outputs,Read:assets,Write:assets,Read:registry,Write:registry -apply

s3.configure -access_key=4f892d9edc9331b338f7b0ac204c6e88 -secret_key=f9fd903b3a26ee66222d3794eb2a4827 -user=piper -actions=Read:artefacts,Write:artefacts,Read:outputs,Write:outputs,Read:assets,Write:assets,Read:registry,Write:registry -apply

s3.configure -user=piper -delete -apply
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
docker node update --label-add clickhouse=true art-piper-1
docker node update --label-add imgproxy=true art-piper-1
docker node update --label-add kafka=true art-piper-1
docker node update --label-add mongo=true art-piper-1
docker node update --label-add piper-worker=true art-piper-2
docker node update --label-add piper-backend=true art-piper-1
docker node update --label-add piper-sockets=true art-piper-1
docker node update --label-add piper-periodic=true art-piper-2
docker node update --label-add piper-oauth=true art-piper-1
docker node update --label-add redis=true art-piper-1
docker node update --label-add seaweedfs=true art-piper-1
docker node update --label-add seaweedfs-filer=true art-piper-1
```

## Monitoring

`vmagent` scrapes every service on the `monitoring` network that has
`prometheus-job` and `prometheus-port` deploy labels. The `deno` service is
scraped as `job="deno"` on port `9464` (`/metrics`); its Grafana dashboard is
`grafana/piper-deno.json` in the
[piper-deno](https://github.com/my-piper/piper-deno) repository.
