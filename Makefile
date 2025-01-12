include config/swarm.env
export

SWARM_ARGS=-c compose.yaml -c components/piper.yaml -c components/monitoring.yaml -c components/ai.yaml -c components/storage.yaml -c components/seaweedfs.yaml
# SWARM_ARGS=-c compose.yaml 

up:
	docker stack deploy ${SWARM_ARGS} ${SWARM_STACK_NAME} --with-registry-auth

status:
	docker stack services ${SWARM_STACK_NAME}
