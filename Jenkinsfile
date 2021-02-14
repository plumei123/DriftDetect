pipeline {
    agent any
	parameters {
		choice(
            name: 'StackName',
            choices: ['EKS-Demo-vpc', 'EKS-Demo-Cluster', 'EKS-Demo-Nodegroup', 'nginxecr'],
            description: 'Currently running StackName'
        )
    }
    environment {
		REGION="us-east-2";
    }	
    stages {
        stage('CleanWorkSpace') {
            steps {
                sh 'rm -rf *'
                checkout scm
            }
        }
		 
		stage('Drift Detect') {
            steps {	
                //Initiate drift detection,check result status	
                sh '''
                    echo " The environment is ${params.StackName}"
					chmod +x ./deploy_ekscluster_all.sh
					sh ./check-drift.sh ${params.StackName} $REGION
			    '''
            }
        }
	}
}
