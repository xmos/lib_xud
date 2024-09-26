// This file relates to internal XMOS infrastructure and should be ignored by external users

@Library('xmos_jenkins_shared_library@v0.34.0') _

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
        runLibraryChecks("${WORKSPACE}/${REPO}", "v2.0.1")
      }
    }

    stage('Build documentation') {
          steps {
            dir("${REPO}") {
              withXdoc("feature/update_xdoc_3_3_0") {
                withTools(params.TOOLS_VERSION) {
                  dir("${REPO}/doc") {
                    sh "xdoc xmospdf"
                  }
                  dir("examples/AN00124_CDC_VCOM_class/doc") {
                    sh "xdoc xmospdf"
                  }
                  dir("examples/AN00125_mass_storage_class/doc") {
                    sh "xdoc xmospdf"
                  }
                  dir("examples/AN00126_printer_class/doc") {
                    sh "xdoc xmospdf"
                  }
                  dir("examples/AN00127_video_class/doc") {
                    sh "xdoc xmospdf"
                  }
                  dir("examples/AN00129_hid_class/doc") {
                    sh "xdoc xmospdf"
                  }
                  dir("examples/AN00131_CDC_EDC_class/doc") {
                    sh "xdoc xmospdf"
                  }
                  dir("examples/AN00132_image_class/doc") {
                    sh "xdoc xmospdf"
                  }
                  dir("examples/AN00135_test_and_measurement_class/doc") {
                    sh "xdoc xmospdf"
                  }
                }
              }
            }
            // Archive all the generated .pdf docs
            archiveArtifacts artifacts: "${REPO}/**/pdf/*.pdf"
          }
        }  // Build documentation

    stage('Tests')
    {
      steps {
        dir("${REPO}/tests"){
          viewEnv(){
            withVenv{
                runPytest('--numprocesses auto --smoke --enabletracing')
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
