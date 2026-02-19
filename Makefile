-include config/swarm.env
export

SWARM_SOURCES=$(shell find ./components -maxdepth 1 -name "*.yaml")
SWARM_FILES=$(patsubst %,-c %,$(SWARM_SOURCES))
PROJECT_ROOT := $(shell dirname $(CURDIR))
DEVOPS_DIR   := $(shell basename $(CURDIR))

DATE := $(shell date +%Y%m%d_%H%M%S)
BACKUP_DAY=$(shell date +%a)
BACKUP_DIR=/var/backups/piper

BACKUP_DIR_MONGO := ${BACKUP_DIR}/mongo/${BACKUP_DAY}
BACKUP_DIR_CLICKHOUSE := ${BACKUP_DIR}/clickhouse/${BACKUP_DAY}
BACKUP_DIR_REDIS := ${BACKUP_DIR}/redis/${BACKUP_DAY}
BACKUP_DIR_CONFIGS:= ${BACKUP_DIR}/configs/${BACKUP_DAY}

BACKUP_LATEST_MONGO=${BACKUP_DIR}/mongo/latest
BACKUP_LATEST_CLICKHOUSE=${BACKUP_DIR}/clickhouse/latest
BACKUP_LATEST_REDIS=${BACKUP_DIR}/redis/latest
BACKUP_LATEST_CONFIGS=${BACKUP_DIR}/configs/latest

BACKUP_CONFIG_ARCHIVE=${BACKUP_DIR_CONFIGS}/$(shell date +%d%m%Y_%H-%M).tar.gz

up:
	docker stack deploy ${SWARM_FILES} ${SWARM_STACK_NAME} --with-registry-auth

status:
	docker stack services ${SWARM_STACK_NAME}

.PHONY: install
install:
	./install/install.sh

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
	ln -sfn ${BACKUP_DIR_MONGO} ${BACKUP_LATEST_MONGO}
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
	tar -czf ${BACKUP_DIR_CLICKHOUSE}/clickhouse-${DATE}.tar.gz -C /var/backups/piper/clickhouse clickhouse-backup
	ln -sfn ${BACKUP_DIR_CLICKHOUSE} ${BACKUP_LATEST_CLICKHOUSE}
	rm -rf /var/backups/piper/clickhouse/clickhouse-backup
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
	ln -sfn ${BACKUP_DIR_REDIS} ${BACKUP_LATEST_REDIS}
	@echo "Backup of redis completed: ${BACKUP_DIR_REDIS}/dump.rdb"

.PHONY: backup-configs
backup-configs:
	@echo "Backing up Swarm configurations..."
	mkdir -p ${BACKUP_DIR_CONFIGS}
	rm -rf ${BACKUP_DIR_CONFIGS}/*
	tar -czf ${BACKUP_CONFIG_ARCHIVE} \
		--exclude='.git' \
		-C $(PROJECT_ROOT) \
		$(DEVOPS_DIR)/
	ln -sfn ${BACKUP_DIR_CONFIGS} ${BACKUP_LATEST_CONFIGS}
	@echo "Config backup created: ${BACKUP_CONFIG_ARCHIVE}"
