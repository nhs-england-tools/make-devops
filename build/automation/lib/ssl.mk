DOMAINS := $(or $(DOMAINS), $(NAME))

ssl-generate-certificate: ### Generate self-signed certificate - mandatory: DIR,NAME=[file and single domain name]; optional: DOMAINS='*.domain1,DNS:*.domain2'
	rm -f $(DIR)/$(NAME).{crt,key,pem,p12}
	openssl req \
		-new -x509 -nodes -sha256 \
		-newkey rsa:4096 \
		-days 3650 \
		-subj "/O=$(NAME)/OU=$(NAME)/CN=$(NAME)" \
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
