// This file relates to internal XMOS infrastructure and should be ignored by external users

@Library('xmos_jenkins_shared_library@v0.55.0') _

getApproval()

pipeline {

  agent none

  parameters {
    string(
      name: 'TOOLS_VERSION',
      // Waiting for XTC tools release with USB fixes...
      defaultValue: '-j -b markp_xsim_expose_signals_from_usb_shim latest',
      description: 'The XTC tools version'
    )
    string(
      name: 'XMOSDOC_VERSION',
      defaultValue: 'v8.1.2',
      description: 'The xmosdoc version'
    )
    string(
      name: 'INFR_APPS_VERSION',
      defaultValue: 'v3.6.0',
      description: 'The infr_apps version'
    )
    choice(name: 'TEST_LEVEL', choices: ['smoke', 'default', 'extended'],
            description: 'The level of test coverage to run'
    )
  }
  options {
    skipDefaultCheckout()
    timestamps()
    buildDiscarder(xmosDiscardBuildSettings(onlyArtifacts = false))
  }

  stages {
    stage('🏗️ Build and test') {
      agent {
        label 'x86_64 && linux && documentation'
      }
      stages {
        stage('Checkout') {
          steps {
            println "Stage running on ${env.NODE_NAME}"
            script {
              def (server, user, repo) = extractFromScmUrl()
              env.REPO_NAME = repo
            }
            dir(REPO_NAME){
              checkoutScmShallow()
            }
          }
        }
        stage('Examples build') {
          steps {
            dir("${REPO_NAME}/examples") {
              xcoreBuild()
            }
          }
        }
        stage('Library checks') {
          steps {
            warnError("lib checks") {
              runRepoChecks("${WORKSPACE}/${REPO_NAME}")
            }
          }
        }

        stage('Documentation') {
          steps {
            dir(REPO_NAME) {
              buildDocs()
            }
          }
        }

        stage('Tests')
        {
          steps {
              withTools(params.TOOLS_VERSION) {
                dir("${REPO_NAME}/tests") {
                  createVenv(reqFile: "requirements.txt")
                  withVenv{
                    sh "pytest -v -n auto --testlevel=${params.TEST_LEVEL} --enabletracing --junitxml=pytest_result.xml"
                  }
                } // dir
              } // withTools
          } // steps
          post
          {
            always {
              junit "${REPO_NAME}/tests/pytest_result.xml"
            }
            failure {
              archiveArtifacts artifacts: "${REPO_NAME}/tests/logs/*.txt", fingerprint: true, allowEmptyArchive: true
            }
          }
        }

        stage("Archive lib") {
            steps
            {
                archiveSandbox(REPO_NAME)
            }
        }
      } // stages
      post {
        cleanup {
          xcoreCleanSandbox()
        }
      }
    } // stage 'build and test'
    stage('🚀 Release') {
      when {
        expression { triggerRelease.isReleasable() }
      }
      steps {
        triggerRelease()
      }
    }
  }
}
