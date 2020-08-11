# Release Runbook

    git checkout master
    name=app # Set your image name accordingly
    make docker-build NAME=$name
    make docker-push NAME=$name
    make project-tag-as-release-candidate IMAGE=$name
    make project-tag-as-environment-deployment IMAGE=$name PROFILE=demo
