pipeline {
  /*
    Description: TODO:
      make project-tag-as-environment-deployment PROFILE=[from the user input] COMMIT=[from the user input] ARTEFACTS=proxy,ui,api
      make git-tag-create-environment-deployment PROFILE=[from the user input] COMMIT=[from the user input]
      # This should trigger the Jenkinsfile.production
   */
  agent { label "jenkins-slave" }
  options {
    buildDiscarder(logRotator(daysToKeepStr: "7", numToKeepStr: "13"))
    disableConcurrentBuilds()
    parallelsAlwaysFailFast()
    timeout(time: 5, unit: "MINUTES")
  }
  environment {
    BUILD_DATE = sh(returnStdout: true, script: "date -u +'%Y-%m-%dT%H:%M:%S%z'").trim()
  }
}
