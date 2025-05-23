-include config/swarm.env
export

SWARM_SOURCES=$(shell find ./components -maxdepth 1 -name "*.yaml")
SWARM_FILES=$(patsubst %,-c %,$(SWARM_SOURCES))

up:
	docker stack deploy ${SWARM_FILES} ${SWARM_STACK_NAME} --with-registry-auth

status:
	docker stack services ${SWARM_STACK_NAME}

.PHONY: install
install:
	./install/install.sh