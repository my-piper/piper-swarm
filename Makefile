export

SWARM_STACK_NAME=piper

up:
	docker stack deploy --compose-file docker-compose.yml ${SWARM_STACK_NAME} --with-registry-auth
status:
	docker stack services ${SWARM_STACK_NAME}
