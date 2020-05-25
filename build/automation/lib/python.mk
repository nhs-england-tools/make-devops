PYTHON_VERSION = 3.8.2
PYTHON_BASE_PACKAGES = \
	black \
	boto3 \
	bpython \
	configparser \
	flake8 \
	mypy \
	pygments \
	pylint \
	pyyaml

python-virtualenv: ### Setup Python virtual environment - optional: PYTHON_VERSION
	brew update
	brew upgrade pyenv
	pyenv install --skip-existing $(PYTHON_VERSION)
	pyenv virtualenv --force $(PYTHON_VERSION) $(PROJECT_GROUP_SHORT)-$(PROJECT_NAME)
	pyenv local $(PROJECT_GROUP_SHORT)-$(PROJECT_NAME)
	pip install --upgrade pip
	pip install $(PYTHON_BASE_PACKAGES)
	ln -sfv ~/.pyenv/versions/$(PYTHON_VERSION) ~/.pyenv/versions/default

python-virtualenv-clean: ### Clean up Python virtual environment - optional: PYTHON_VERSION
	rm -rf \
		.python-version \
		~/.pyenv/versions/$(PYTHON_VERSION)/envs/$(PROJECT_GROUP_SHORT)-$(PROJECT_NAME)
