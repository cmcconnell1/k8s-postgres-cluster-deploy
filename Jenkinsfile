pipeline {
    agent any
    // not sure what this does but see it everywhere like
    // https://jenkins.io/doc/tutorials/build-a-multibranch-pipeline-project/
    environment {
        CI = 'true'
    }
    stages {
        stage('Deploy to DEV using ~/.kube/dev-usw2/kubeconfig-postgres-operator') {
            when { 
                branch 'development' 
            }
            steps {
                script {
                    //withAWS(credentials:'ecr-creds', region: 'us-west-2') {
                    withAWS(region:'us-west-2') {
                        sh """
                            for i in `seq 1 10`; do \
                            kubectl -n postgres-operator --kubeconfig=/var/lib/jenkins/.kube/dev-usw2/kubeconfig-postgres-operator apply --recursive -f ./manifests/development && break || \
                            sleep 10; \
                            done; \
                        """
                    }    
                }
            }
        }
//        stage('IF you have stage... Deploy to STAGE using kubeconfig-postgres-operator') {
//            when {
//                branch 'staging'  
//            }
//            steps {
//                script {
//                    withAWS(region:'us-west-2') {
//                        sh """
//                            for i in `seq 1 10`; do \
//                            kubectl -n postgres-stage --kubeconfig=/var/lib/jenkins/.kube/stage/kubeconfig-postgres-operator apply --recursive -f ./manifests/staging && break || \
//                            sleep 10; \
//                            done; \
//                        """
//                    }    
//                }
//            }
//        }
//        stage('Deploy to PROD using ~/.kube/prod/kubeconfig-postgres-operator') {
//            when {
//                branch 'production'  
//            }
//            steps {
//                script {
//                    withAWS(region:'us-west-2') {
//                        sh """
//                            for i in `seq 1 10`; do \
//                            kubectl -n postgres --kubeconfig=/var/lib/jenkins/.kube/prod-usw2/kubeconfig-postgres-operator apply --recursive -f ./manifests/production && break || \
//                            sleep 10; \
//                            done; \
//                        """
//                    }    
//                }
//            }
//        }
    }
}
