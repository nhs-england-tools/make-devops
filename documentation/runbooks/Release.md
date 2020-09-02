# Release Runbook

    git checkout master
    name=app # Set your image name accordingly
    make docker-build NAME=$name
    make docker-push NAME=$name
    make project-tag-as-release-candidate ARTEFACT=$name
    make project-tag-as-environment-deployment ARTEFACT=$name PROFILE=demo

Make sure the default version of the image is in the following format `YYYYmmddHHMMSS-hash`.
