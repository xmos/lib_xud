// This file relates to internal XMOS infrastructure and should be ignored by external users

@Library('xmos_jenkins_shared_library@develop') _

getApproval()

pipeline {
  agent {
    label 'x86_64 && linux'
  }
  environment {
    REPO = 'lib_xud'
    VIEW = getViewName(REPO)
  }
  options {
    buildDiscarder(xmosDiscardBuildSettings())
    skipDefaultCheckout()
    timestamps()
  }
  parameters {
    string(
      name: 'TOOLS_VERSION',
      defaultValue: '15.3.0',
      description: 'The XTC tools version'
    )
  }

  stages {
    stage('Get view') {
      steps {
        xcorePrepareSandbox("${VIEW}", "${REPO}")
      }
    }
    stage('Build examples') {
      steps {
        println "Stage running on ${env.NODE_NAME}"
        dir("${REPO}") {
          checkout scm

          dir("examples") {
            withTools(params.TOOLS_VERSION) {
              sh 'cmake -G "Unix Makefiles" -B build'
              sh 'xmake -C build -j'
            }
          }
        }
      }
    }  // Build examples

    stage('Library checks') {
      steps {
        runLibraryChecks("${WORKSPACE}/${REPO}")
      }
    }

    stage('Tests')
    {
      steps {
        dir("${REPO}/tests"){
          viewEnv(){
            withVenv{
                runPytest('--numprocesses=8 --smoke --enabletracing')
            }
          }
        }
      }
      post
      {
        failure
        {
          archiveArtifacts artifacts: "${REPO}/tests/logs/*.txt", fingerprint: true, allowEmptyArchive: true
        }
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
