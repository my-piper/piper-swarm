-include config/swarm.env
export

SWARM_SOURCES=$(shell find ./components -maxdepth 1 -name "*.yaml")
SWARM_FILES=$(patsubst %,-c %,$(SWARM_SOURCES))

# envs for backup
PG_USER=postgres
PG_DB=nocodb

DATE := $(shell date +%Y%m%d_%H%M%S)
BACKUP_DAY=$(shell date +%a)

BACKUP_DIR_PG := /var/backups/piper/postgres/${BACKUP_DAY}
BACKUP_DIR_MONGO := /var/backups/piper/mongo/${BACKUP_DAY}
BACKUP_DIR_CLICKHOUSE := /var/backups/piper/clickhouse/${BACKUP_DAY}
BACKUP_DIR_NCDATA := /var/backups/piper/nocodb-data/${BACKUP_DAY}
BACKUP_DIR_REDIS := /var/backups/piper/redis/${BACKUP_DAY}

LATEST_LINK_PG=/var/backups/piper/postgres/latest
LATEST_LINK_MONGO=/var/backups/piper/mongo/latest
LATEST_LINK_CLICKHOUSE=/var/backups/piper/clickhouse/latest
LATEST_LINK_NCDATA=/var/backups/piper/nocodb-data/latest
LATEST_LINK_REDIS=/var/backups/piper/redis/latest

up:
	docker stack deploy ${SWARM_FILES} ${SWARM_STACK_NAME} --with-registry-auth

status:
	docker stack services ${SWARM_STACK_NAME}

.PHONY: install
install:
	./install/install.sh

.PHONY: backup-db
backup-db:
	@mkdir -p ${BACKUP_DIR_PG}
	rm -rf ${BACKUP_DIR_PG}/*
	@echo "Checking for Postgres container..."
	$(eval CONTAINER_ID_PG := $(shell docker ps --filter "label=com.docker.swarm.service.name=${SWARM_STACK_NAME}_postgres" -q | head -n1))
	@if [ -z "${CONTAINER_ID_PG}" ]; then \
		echo "Error: Postgres container not found. Is the stack running?"; \
		exit 1; \
	fi
	@echo "Create backup Postgres from container ${CONTAINER_ID_PG}..."
	docker exec -i ${CONTAINER_ID_PG} pg_dump -U ${PG_USER} -d ${PG_DB} -Fc \
		> ${BACKUP_DIR_PG}/db_${DATE}.dump
	ln -sfn ${BACKUP_DIR_PG} ${LATEST_LINK_PG}
	@echo "Backup Postgres completed successfully: ${BACKUP_DIR_PG}/db_${DATE}.dump"

.PHONY: backup-mongo
backup-mongo:
	@mkdir -p $(BACKUP_DIR_MONGO)
	rm -rf ${BACKUP_DIR_MONGO}/*
	@echo "Checking for MONGO container..."
	$(eval CONTAINER_ID_MONGO := $(shell docker ps --filter "label=com.docker.swarm.service.name=${SWARM_STACK_NAME}_mongo" -q | head -n1))
	@if [ -z "${CONTAINER_ID_MONGO}" ]; then \
		echo "Error: Mongo container not found. Is the stack running?"; \
		exit 1; \
	fi
	@echo "Create backup MONGO from container ${CONTAINER_ID_MONGO}..."
	docker exec -i ${CONTAINER_ID_MONGO} /usr/bin/mongodump -j 12 --gzip --archive > ${BACKUP_DIR_MONGO}/db_${DATE}.dump
	ln -sfn ${BACKUP_DIR_MONGO} ${LATEST_LINK_MONGO}
	@echo "Backup Mongo completed successfully: $(BACKUP_DIR_MONGO)/db_${DATE}.dump"

.PHONY: backup-clickhouse
backup-clickhouse:
	@mkdir -p $(BACKUP_DIR_CLICKHOUSE)
	rm -rf ${BACKUP_DIR_CLICKHOUSE}/*
	@echo "Checking for CLICKHOUSE container..."
	$(eval CONTAINER_ID_CLICKHOUSE := $(shell docker ps --filter "label=com.docker.swarm.service.name=${SWARM_STACK_NAME}_clickhouse" -q | head -n1))
	@if [ -z "${CONTAINER_ID_CLICKHOUSE}" ]; then \
	echo "Error: Clickhouse container not found. Is the stack running?"; \
		exit 1; \
	fi
	@echo "Create backup Clickhouse from container ${CONTAINER_ID_CLICKHOUSE}..."
	docker exec -i ${CONTAINER_ID_CLICKHOUSE} clickhouse-client --query "BACKUP DATABASE piper TO Disk('backups', 'clickhouse-backup')"
	tar -czf ${BACKUP_DIR_CLICKHOUSE}/clickhouse-${DATE}.tar.gz -C /var/backups/clickhouse clickhouse-backup
	ln -sfn ${BACKUP_DIR_CLICKHOUSE} ${LATEST_LINK_CLICKHOUSE}
	rm -rf /var/backups/clickhouse/clickhouse-backup
	@echo "Backup Clickhouse completed successfully: ${BACKUP_DIR_CLICKHOUSE}/clickhouse-${DATE}.tar.gz"

.PHONY: backup-redis
backup-redis:
	@mkdir -p ${BACKUP_DIR_REDIS}
	rm -rf ${BACKUP_DIR_REDIS}/*
	@echo "Creating backup of redis volume..."
	docker run --rm \
		-v ${SWARM_STACK_NAME}_redis-data:/source:ro \
		-v ${BACKUP_DIR_REDIS}:/backup \
		alpine cp /source/dump.rdb /backup/dump.rdb
	ln -sfn ${BACKUP_DIR_REDIS} ${LATEST_LINK_REDIS}
	@echo "Backup of redis completed: ${BACKUP_DIR_REDIS}/dump.rdb"

.PHONY: backup-nocodb
backup-nocodb:
	@mkdir -p ${BACKUP_DIR_NCDATA}
	rm -rf ${BACKUP_DIR_NCDATA}/*
	@echo "Creating backup of nocodb-data volume..."
	docker run --rm \
		-v ${SWARM_STACK_NAME}_nocodb-data:/source:ro \
		-v ${BACKUP_DIR_NCDATA}:/backup \
		alpine tar -czf /backup/nocodb-data-${DATE}.tar.gz -C /source .
	ln -sfn ${BACKUP_DIR_NCDATA} ${LATEST_LINK_NCDATA}
	@echo "Backup of nocodb-data completed: ${BACKUP_DIR_NCDATA}/nocodb-data-${DATE}.tar.gz"