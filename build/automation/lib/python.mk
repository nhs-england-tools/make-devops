PYTHON_VERSION = 3.8.2

python-virtualenv: ### Setup Python virtual environment - optional: PYTHON_VERSION
	pyenv install --skip-existing $(PYTHON_VERSION)
	pyenv virtualenv --force $(PYTHON_VERSION) $(PROJECT_GROUP_SHORT)-$(PROJECT_NAME)
	pyenv local $(PROJECT_GROUP_SHORT)-$(PROJECT_NAME)

python-virtualenv-clean: ### Clean up Python virtual environment - optional: PYTHON_VERSION
	rm -rf \
		.python-version \
		~/.pyenv/versions/$(PYTHON_VERSION)/envs/$(PROJECT_GROUP_SHORT)-$(PROJECT_NAME)
