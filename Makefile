include config/swarm.env
export

up:
	docker stack deploy --compose-file compose.yml ${SWARM_STACK_NAME} --with-registry-auth

status:
	docker stack services ${SWARM_STACK_NAME}
