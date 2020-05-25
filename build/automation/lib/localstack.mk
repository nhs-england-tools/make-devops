LOCALSTACK_HOST = localstack.$(PROJECT_NAME_SHORT).local

localstack-start: ### Start localstack
	mkdir -p $(TMP_DIR)/localstack
	cp -f $(LIB_DIR)/localstack/server.test.* $(TMP_DIR)/localstack
	make docker-config
	make docker-compose-start YML=$(LIB_DIR)/localstack/docker-compose.localstack.yml
	sleep 5

localstack-stop: ### Stop localstack
	make docker-compose-stop YML=$(LIB_DIR)/localstack/docker-compose.localstack.yml
	rm -rf $(TMP_DIR)/localstack
