pipeline {
    agent any
    
    environment {
        PATH = "${PATH}:${getTerraformPath()}"
        AMI_ID="stack-ami-${BUILD_NUMBER}"
        VERSION = "1.0.${BUILD_NUMBER}"
    }
    stages{
        
        stage('Initial Stage') {
            steps {
                script {
                    def userInput = input(id: 'confirm', message: 'Start Pipeline?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Start Pipeline', name: 'confirm'] ])
                }
            }
        }
        
        stage('Packer AMI Build'){
            steps {
                sh '''
                cd images
                sed -i "s/ami-stack-'[0-9]*$'/'${AMI_ID}'/" ./image.pkr.hcl 
                export PACKER_LOG=1
                export PACKER_LOG_PATH=$WORKSPACE/packer.log
                packer build -force image.pkr.hcl 
                '''
            }
        }
        
        stage('Terraform init'){
            steps {
                sh """
                cd instances
                terraform init -upgrade
                """
            }
        }
        
        stage('Terraform Plan'){
            steps {
                sh """
                cd instances
                terraform plan -out=tfplan -input=false
                """
            }
        }
        
        stage('Deploy Test Instance'){
            steps {
                sh """
                cd instances
                terraform apply -auto-approve
                """
            }
        }
        
        stage('Wait for Inspector Scan'){
            steps {
                script {
                    echo "Waiting 2 minutes for Inspector v2 to scan the instance..."
                    sleep(time: 2, unit: 'MINUTES')
                }
            }
        }
        
        stage('Get Inspector Findings'){
            steps {
                sh '''
                echo "=== Retrieving Inspector v2 Findings ==="
                aws inspector2 list-findings --region us-east-1 --max-results 10 > inspector-findings.json || echo "No findings yet"
                
                if [ -f inspector-findings.json ]; then
                    echo "Inspector findings saved to inspector-findings.json"
                    cat inspector-findings.json
                fi
                '''
            }
        }
        
        stage('Pause for Review'){
            steps {
                input message: 'Instance deployed and scanned. Review findings and approve to destroy.', ok: 'Destroy'
            }
        }
        
        stage('Cleanup Test Instance'){
            steps {
                sh """
                cd instances
                terraform destroy -auto-approve
                """
            }
        }
    }
    
    post {
        success {
            slackSend(
                channel: '#stackjenkins',
                color: 'good',
                message: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' completed successfully. AMI Created: ${env.AMI_ID}. Build URL: ${env.BUILD_URL}"
            )
        }
        failure {
            slackSend(
                channel: '#stackjenkins',
                color: 'danger',
                message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' failed. Build URL: ${env.BUILD_URL}"
            )
        }
    }
}

def getTerraformPath(){
    def tfHome= tool name: 'terraform-14', type: 'terraform'
    return tfHome
}
