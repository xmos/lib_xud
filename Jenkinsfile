// This file relates to internal XMOS infrastructure and should be ignored by external users

@Library('xmos_jenkins_shared_library@v0.34.0') _

def clone_test_deps() {
  dir("${WORKSPACE}") {
    sh "git clone git@github.com:xmos/test_support"
    sh "git -C test_support checkout c820ebe67bea0596dabcdaf71a590c671385ac35"
  }
}

getApproval()

pipeline {
  agent {
    label 'x86_64 && linux'
  }
  environment {
    REPO = 'lib_xud'
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
        runLibraryChecks("${WORKSPACE}/${REPO}", "v2.0.1")
      }
    }

    stage('Tests')
    {
      steps {

          // Note, moves to WORKSPACE
          clone_test_deps()

          withTools(params.TOOLS_VERSION) {
            dir("${REPO}/tests") {
              createVenv(reqFile: "requirements.txt")
              withVenv{
                runPytest('--numprocesses=8 --smoke --enabletracing')
              }
            } // dir
          } // withTools
      } // steps
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
    cleanup {
      xcoreCleanSandbox()
    }
  }
}
