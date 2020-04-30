pipeline {
  agent {
    label 'jenkins-slave'
  }
  options {
    buildDiscarder(logRotator(numToKeepStr: '13'))
    disableConcurrentBuilds()
  }
  stages {
    stage("Show Variables") {
      steps {
        script {
          sh 'make devops-print-variables'
        }
      }
    }
  }
  post {
  }
}
