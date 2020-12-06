pipeline {
  agent any
  environment {
    PROD_VERSION = "1.0.${env.BUILD_ID}"
  }
  stages {
    stage('Verify Branch') {
      steps {
        echo "${GIT_BRANCH}"
      }
    }
    stage('Run Unit Tests') {
      steps {
        powershell(script: """
          cd Server
          dotnet test
          cd ..
        """)
      }
    }
    stage('Docker Build') {
      steps {
        powershell(script: 'docker-compose build')
        powershell(script: 'docker build -t pesho1/carrentalsystem-user-client-development --build-arg configuration=development .\\Client\\')
        powershell(script: 'docker build -t pesho1/carrentalsystem-user-client-production --build-arg configuration=production .\\Client\\')
        powershell(script: 'docker images -a')
      }
    }
    stage('Run Test Application') {
      steps {
        powershell(script: 'docker-compose up -d')
      }
    }
    stage('Run Local Integration Tests') {
      steps {
        powershell(script: './Tests/ContainerTests.local.ps1')
      }
    }
    stage('Stop Test Application') {
      steps {
        powershell(script: 'docker-compose down')
        // powershell(script: 'docker volumes prune -f')
      }
      post {
        success {
          echo "Build successfull! You should deploy! :)"
        }
        failure {
          echo "Build failed! You should receive an e-mail! :("
        }
      }
    }
    stage('Push Images') {
      when { anyOf { branch 'main'; branch 'development' } }
      steps {
        script {
          def images = [
            "pesho1/carrentalsystem-identity-service",
            "pesho1/carrentalsystem-dealers-service",
            "pesho1/carrentalsystem-statistics-service",
            "pesho1/carrentalsystem-notifications-service",
            "pesho1/carrentalsystem-user-client",
            "pesho1/carrentalsystem-admin-client",
            "pesho1/carrentalsystem-watchdog-service",
            "pesho1/carrentalsystem-user-client-development",
            "pesho1/carrentalsystem-user-client-production"
          ]

          docker.withRegistry('https://index.docker.io/v1/', 'DockerHub') {
            for (imageName in images) {
              echo "Pushing ${imageName}"
              
              def image = docker.image(imageName)
              
              if (env.BRANCH_NAME == 'main') {
                image.push(PROD_VERSION)
              }

              if (env.BRANCH_NAME == 'development') {
                image.push('latest')
              }
            }
          }
        }
      }
    }
    stage('Deploy Development') {
      when { branch 'development' }
      steps {
        withKubeConfig([credentialsId: 'DevelopmentServer', serverUrl: 'https://car-rental-system-dns-18b73077.hcp.westeurope.azmk8s.io']) {
          powershell(script: 'kubectl apply -f ./.k8s/.environment/development.yml')
          powershell(script: 'kubectl apply -R -f ./.k8s/objects/')
          powershell(script: 'kubectl set image deployments/user-client user-client=pesho1/carrentalsystem-user-client-development:latest')
        }
      }
    }
    stage('Run Dev Integration Tests') {
      steps {
        powershell(script: './Tests/ContainerTests.dev.ps1')
      }
    }
    stage('Confirm Production Deployment') {
      when { branch 'main' }

      steps {
        script {
          def runRelease = false
          timeout(time: 60, unit: 'SECONDS') {
            runRelease = input(
              message: 'Deploy to Production', parameters: [
              [$class: 'BooleanParameterDefinition', defaultValue: false, description: '', name: 'Please confirm you want to deploy']
            ])
          }

          if(!runRelease) {
            def user = err.getCauses()[0].getUser()
            if('SYSTEM' == user.toString()) {
                echo "Aborted by System (timeout)"
            } else {
                echo "Aborted by: [${user}]"
            }
          }
          else {
            stage('Deploy Production') {
              def images = [
                "pesho1/carrentalsystem-user-client": "pesho1/carrentalsystem-user-client-production",
                "pesho1/carrentalsystem-admin-client" : "pesho1/carrentalsystem-admin-client",
                "pesho1/carrentalsystem-watchdog-service": "pesho1/carrentalsystem-watchdog-service",
                "pesho1/carrentalsystem-dealers-service": "pesho1/carrentalsystem-dealers-service",
                "pesho1/carrentalsystem-identity-service": "pesho1/carrentalsystem-identity-service",
                "pesho1/carrentalsystem-notifications-service" : "pesho1/carrentalsystem-notifications-service",
                "pesho1/carrentalsystem-statistics-service" : "pesho1/carrentalsystem-statistics-service"
              ]
              def files = findFiles(glob: "**/.k8s/**/*.yml")
              def filesStr = files.join(',')

              for (image in images) {
                contentReplace(
                  configs: [
                    fileContentReplaceConfig(
                      configs: [
                        fileContentReplaceItemConfig(
                          search: image.key,
                          replace: "${image.value}:${PROD_VERSION}"
                          // matchCount: 1
                        )
                      ],
                      fileEncoding: 'UTF-8',
                      filePath: filesStr
                    )
                  ]
                )
              }
              
              withKubeConfig([credentialsId: 'ProductionServer', serverUrl: 'https://car-rental-system-production-dns-94a2f482.hcp.uksouth.azmk8s.io']) {
                powershell(script: 'kubectl apply -f ./.k8s/.environment/production.yml')
                powershell(script: 'kubectl apply -R -f ./.k8s/objects/')
                // powershell(script: "kubectl set image deployments/user-client user-client=pesho1/carrentalsystem-user-client-production:${PROD_VERSION}")
              }
            }
          }
        }
      }
    }
  }
  // post {
  //   always {
  //       emailext body: "${currentBuild.currentResult}: Job ${env.JOB_NAME} build ${env.BUILD_NUMBER}\n More info at: ${env.BUILD_URL}",
  //         recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
  //         subject: "Jenkins Build ${currentBuild.currentResult}: Job ${env.JOB_NAME}"
  //   }
  // }
}
