CERTIFICATE_DIR = $(ETC_DIR)/certificate

ssl-generate-certificate-project: ### Generate self-signed certificate for the project - optional: DOMAINS='*.domain1,*.domain2'
	domains="localhost,DNS:$(PROJECT_NAME_SHORT).$(PROJECT_GROUP_SHORT),DNS:*.$(PROJECT_NAME_SHORT).$(PROJECT_GROUP_SHORT),DNS:*.$(TEXAS_HOSTED_ZONE_NONPROD),DNS:*.$(TEXAS_HOSTED_ZONE_PROD),"
	for domain in $$(echo $(DOMAINS) | tr "," "\n"); do
		domains+="DNS:$${domain},"
	done
	make ssl-generate-certificate \
		DIR=$(CERTIFICATE_DIR) \
		NAME=certificate \
		DOMAINS=$$(printf "$$domains" | head -c -1)

ssl-generate-certificate: ### Generate self-signed certificate - mandatory: DIR,NAME=[file name],DOMAINS='*.domain1,DNS:*.domain2'
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

ssl-trust-certificate: ### Trust self-signed certificate - mandatory: FILE=[path to .pem file]
	sudo security add-trusted-cert -d \
		-r trustRoot \
		-k /Library/Keychains/System.keychain \
		$(FILE)
