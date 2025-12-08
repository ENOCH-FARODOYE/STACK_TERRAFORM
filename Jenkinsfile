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
        
        stage('Pause for Review'){
            steps {
                input message: 'Instance deployed. Review and approve to destroy.', ok: 'Destroy'
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
}

def getTerraformPath(){
    def tfHome= tool name: 'terraform-14', type: 'terraform'
    return tfHome
}
