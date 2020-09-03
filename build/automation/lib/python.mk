PYTHON_VERSION_MAJOR = 3
PYTHON_VERSION_MINOR = 8
PYTHON_VERSION_PATCH = 5
PYTHON_VERSION = $(PYTHON_VERSION_MAJOR).$(PYTHON_VERSION_MINOR).$(PYTHON_VERSION_PATCH)
PYTHON_BASE_PACKAGES = \
	awscli-local==0.8 \
	awscli==1.18.131 \
	black==20.8b1 \
	boto3==1.14.54 \
	bpython \
	configparser \
	coverage \
	diagrams \
	flake8 \
	mypy \
	pygments \
	pylint \
	pyyaml \
	requests==2.24.0

python-virtualenv: ### Setup Python virtual environment - optional: PYTHON_VERSION
	brew update
	brew upgrade pyenv
	pyenv install --skip-existing $(PYTHON_VERSION)
	pyenv local $(PYTHON_VERSION)
	pip install --upgrade pip
	pip install $(PYTHON_BASE_PACKAGES)
	sed -i 's;    "python.linting.flake8Path":.*;    "python.linting.flake8Path": "~/.pyenv/versions/$(PYTHON_VERSION)/bin/flake8",;g' project.code-workspace
	sed -i 's;    "python.linting.mypyPath":.*;    "python.linting.mypyPath": "~/.pyenv/versions/$(PYTHON_VERSION)/bin/mypy",;g' project.code-workspace
	sed -i 's;    "python.linting.pylintPath":.*;    "python.linting.pylintPath": "~/.pyenv/versions/$(PYTHON_VERSION)/bin/pylint",;g' project.code-workspace
	sed -i 's;    "python.pythonPath":.*;    "python.pythonPath": "~/.pyenv/versions/$(PYTHON_VERSION)/bin/python",;g' project.code-workspace

python-virtualenv-clean: ### Clean up Python virtual environment - optional: PYTHON_VERSION
	pyenv uninstall --force $(PYTHON_VERSION)
	rm -rf .python-version
	pyenv global system

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

python-clean: ### Clean up Python project files - mandatory: DIR=[Python project directory]
	[ -z "$(DIR)" ] && (echo "ERROR: Please, specify the DIR"; exit 1)
	find $(DIR) \( \
		-name "__pycache__" -o \
		-name ".mypy_cache" -o \
		-name "*.pyc" -o \
		-name "*.pyd" -o \
		-name "*.pyo" -o \
		-name "coverage.xml" -o \
		-name "db.sqlite3" -o \
	\) -print | xargs rm -rfv
