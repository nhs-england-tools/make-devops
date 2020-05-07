SSL_CERTIFICATE_DIR = $(ETC_DIR)/certificate
SSL_CERTIFICATE_DIR_REL = $(shell echo $(SSL_CERTIFICATE_DIR) | sed "s;$(PROJECT_DIR);;g")

ssl-generate-certificate-project: ### Generate self-signed certificate for the project - optional: DIR=[path to certificate],NAME=[certificate file name],DOMAINS='*.domain1,*.domain2'
	domains="localhost,DNS:$(PROJECT_NAME_SHORT).local,DNS:*.$(PROJECT_NAME_SHORT).local,DNS:$(PROJECT_NAME).local,DNS:*.$(PROJECT_NAME).local,"
	domains+="DNS:$(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT).local,DNS:*.$(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT).local,"
	domains+="DNS:*.$(TEXAS_HOSTED_ZONE_NONPROD),DNS:*.$(TEXAS_HOSTED_ZONE_PROD),"
	for domain in $$(echo $(DOMAINS) | tr "," "\n"); do
		domains+="DNS:$${domain},"
	done
	make ssl-generate-certificate \
		DIR=$(or $(DIR), $(SSL_CERTIFICATE_DIR)) \
		NAME=$(or $(NAME), certificate) \
		DOMAINS=$$(printf "$$domains" | head -c -1)

ssl-generate-certificate: ### Generate self-signed certificate - mandatory: DIR=[path to certificate],NAME=[certificate file name],DOMAINS='*.domain1,DNS:*.domain2'
	rm -f $(DIR)/$(NAME).{crt,key,pem,p12}
	openssl req \
		-new -x509 -nodes -sha256 \
		-newkey rsa:4096 \
		-days 3650 \
		-subj "/O=$(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)/OU=$(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)/CN=$(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)" \
		-reqexts SAN \
		-extensions SAN \
		-config \
			<(cat /etc/ssl/openssl.cnf \
			<(printf '[SAN]\nsubjectAltName=DNS:$(DOMAINS)')) \
		-keyout $(DIR)/$(NAME).key \
		-out $(DIR)/$(NAME).crt
	cat $(DIR)/$(NAME).crt $(DIR)/$(NAME).key > $(DIR)/$(NAME).pem
	openssl pkcs12 \
		-export -passout pass: \
		-in $(DIR)/$(NAME).crt \
		-inkey $(DIR)/$(NAME).key \
		-out $(DIR)/$(NAME).p12
	openssl x509 -text < $(DIR)/$(NAME).crt

ssl-trust-certificate-project: ### Trust self-signed certificate for the project - optional: FILE=[path to .pem file]
	make ssl-trust-certificate \
		FILE=$(SSL_CERTIFICATE_DIR)/certificate.pem

ssl-trust-certificate: ### Trust self-signed certificate - mandatory: FILE=[path to .pem file]
	sudo security add-trusted-cert -d \
		-r trustRoot \
		-k /Library/Keychains/System.keychain \
		$(FILE)
	file=/etc/hosts
	sudo make file-remove-content \
		FILE=$$file \
		CONTENT="\n# BEGIN: $(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)(.)*# END: $(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)\n"
	echo -e "\n# BEGIN: $(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)" | sudo tee -a $$file
	echo "127.0.0.1 $(PROJECT_NAME_SHORT).local" | sudo tee -a $$file
	echo "127.0.0.1 $(PROJECT_NAME).local" | sudo tee -a $$file
	echo "127.0.0.1 $(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT).local" | sudo tee -a $$file
	echo "# END: $(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)" | sudo tee -a $$file
