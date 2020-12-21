TEXAS_VERSION = v2

AWS_DEFAULT_REGION = eu-west-2
AWS_ALTERNATIVE_REGION = eu-west-1
AWS_REGION = $(AWS_DEFAULT_REGION)
AWS_PROFILE = $(PROJECT_ID)-$(AWS_ACCOUNT_NAME)

AWS_ROLE_ADMIN = Admin
AWS_ROLE_READONLY = ReadOnly
AWS_ROLE_DEVELOPER = ServiceDeveloper
AWS_ROLE_SUPPORT = ServiceSupport
AWS_ROLE_PIPELINE = ServiceDeployment
