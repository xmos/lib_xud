@Library('xmos_jenkins_shared_library@v0.16.2') _

getApproval()

pipeline {
  agent {
    label 'x86_64 && brew && macOS'
  }
  environment {
    REPO = 'lib_xud'
    VIEW = getViewName(REPO)
  }
  options {
    skipDefaultCheckout()
    timestamps()
    // on develop discard builds after a certain number else keep forever
    buildDiscarder(logRotator(
        numToKeepStr:         env.BRANCH_NAME ==~ /develop/ ? '100' : '',
        artifactNumToKeepStr: env.BRANCH_NAME ==~ /develop/ ? '100' : ''
    ))
  }
  stages {
    stage('Get view') {
      steps {
        xcorePrepareSandbox("${VIEW}", "${REPO}")
      }
    }
    stage('Library checks') {
      steps {
        xcoreLibraryChecks("${REPO}")
      }
    }
    stage('xCORE builds') {
      steps {
        dir("${REPO}") {
          // xcoreAllAppsBuild('examples')
          xcoreAllAppNotesBuild('examples')
          dir("${REPO}") {
            runXdoc('doc')
          }
        }
        // Archive all the generated .pdf docs
        archiveArtifacts artifacts: "${REPO}/**/pdf/*.pdf", fingerprint: true, allowEmptyArchive: true
      }
    }
    stage('Tests') {
      steps {
        dir("${REPO}/tests"){
          viewEnv(){
            withVenv{
                runPytest('--numprocesses=4 --smoke --enabletracing --xcov')
            }
          }
        }
        archiveArtifacts artifacts: "${REPO}/tests/logs/*.txt", fingerprint: true, allowEmptyArchive: true
        archiveArtifacts artifacts: "${REPO}/tests/logs/*.vcd", fingerprint: true, allowEmptyArchive: true
        archiveArtifacts artifacts: "${REPO}/tests/result/*.txt", fingerprint: true, allowEmptyArchive: true
      }
    }
  }
  post {
    success {
      updateViewfiles()
    }
    cleanup {
      xcoreCleanSandbox()
    }
  }
}
