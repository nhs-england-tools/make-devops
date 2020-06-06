PYTHON_VERSION = 3.8.2
PYTHON_BASE_PACKAGES = \
	awscli-local==0.6 \
	awscli==1.18.74 \
	black \
	boto3==1.13.24 \
	bpython \
	configparser \
	coverage \
	flake8 \
	mypy \
	pygments \
	pylint \
	pyyaml \
	requests==2.23.0

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

python-code-format: ### Format Python code with 'balck' - optional: FILES=[directory, file or pattern]
	make docker-run-tools CMD=" \
		black \
			--line-length 120 \
			$(or $(FILES), $(APPLICATION_DIR)) \
	"

python-code-check: ### Check Python code with 'flake8' - optional: FILES=[directory, file or pattern],EXCLUDE=[comma-separated list]
	make docker-run-tools CMD=" \
		flake8 \
			--max-line-length=120 \
			--exclude */tests/__init__.py,$(EXCLUDE) \
			$(or $(FILES), $(APPLICATION_DIR)) \
	"

python-code-coverage: ### Test Python code with 'coverage' - mandatory: CMD=[test program]; optional: FILES=[directory, file or pattern],EXCLUDE=[comma-separated list]
	make docker-run-tools SH=y CMD=" \
		coverage run \
			--source=$(or $(FILES), $(APPLICATION_DIR)) \
			--omit=*/tests/*,$(EXCLUDE) \
			$(CMD) &&
		coverage report -m && \
		coverage erase \
	"
