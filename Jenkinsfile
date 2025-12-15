// --- BUILD PARAMETERS ---
properties([
    parameters([
        choice(
            name: 'ACTION',
            choices: ['SCALE_UP', 'SCALE_DOWN', 'BUILD_ONLY'],
            description: 'Select the primary action: Build image, Scale up, or Scale down.'
        ),
        string(
            name: 'TARGET_REPLICAS',
            defaultValue: '2',
            description: 'Number of replicas to set for SCALE_UP/SCALE_DOWN actions (e.g., 2 or 0).'
        )
    ])
])

// --- CONFIGURATION VARIABLES ---
def K8S_DEPLOYMENT_NAME = 'ubuntu-app-deployment'
def K8S_NAMESPACE = 'default'
// NOTE: Ensure you have a File Credential named 'kube-config-file' containing your Kubeconfig (~/.kube/config)
def KUBE_CONFIG_CREDENTIAL_ID = 'kube-config-file' 

def IMAGE_NAME = 'ubuntu-deployment'
def IMAGE_TAG = 'latest'

pipeline {
    // CRITICAL FIX: Use the dedicated Linux Agent where Docker/Minikube are installed.
    // REPLACE 'linux-minikube-agent' with the exact name/label you gave your Jenkins Node.
    agent {
        label 'linux-minikube-agent'
    }

    environment {
        FULL_IMAGE_NAME = "${IMAGE_NAME}:${IMAGE_TAG}"
    }

    stages {
        stage('Build Image and Load into Minikube') {
            when { 
                expression { 
                    // Only run this stage if action is BUILD_ONLY or SCALE_UP (which requires a build)
                    params.ACTION == 'BUILD_ONLY' || params.ACTION == 'SCALE_UP' 
                } 
            }
            steps {
                script {
                    echo "--- Building local image and loading into Minikube cache ---"
                    
                    // 1. Build the image (runs on Linux Agent)
                    sh "docker build -t ${env.FULL_IMAGE_NAME} ."
                    
                    // 2. Load the image into the Minikube cluster's cache
                    // This command uses the Docker daemon managed by Minikube on the Agent VM
                    sh "minikube image load ${env.FULL_IMAGE_NAME}" 

                    echo "Image built and loaded into Minikube successfully."
                }
            }
        }

        stage('Update & Scale Kubernetes Deployment') {
            when { 
                expression { 
                    params.ACTION == 'SCALE_UP' || params.ACTION == 'SCALE_DOWN'
                } 
            }
            steps {
                script {
                    // Use withCredentials to securely inject the Kube config file for kubectl access
                    withCredentials([file(credentialsId: KUBE_CONFIG_CREDENTIAL_ID, variable: 'KUBE_CONFIG_PATH')]) {
                        
                        // Set the KUBECONFIG environment variable for this shell session
                        // This tells kubectl where to find the cluster configuration file
                        sh "export KUBECONFIG=\${KUBE_CONFIG_PATH}"
                        
                        if (params.ACTION == 'SCALE_UP') {
                            echo "Patching deployment and scaling to ${params.TARGET_REPLICAS} replicas..."
                            
                            // 1. Patch the Deployment with the new image tag
                            sh "kubectl set image deployment/${K8S_DEPLOYMENT_NAME} ${K8S_DEPLOYMENT_NAME}-container=${env.FULL_IMAGE_NAME} -n ${K8S_NAMESPACE}"
                            
                            // 2. Scale the Deployment
                            sh "kubectl scale deployment/${K8S_DEPLOYMENT_NAME} --replicas=${params.TARGET_REPLICAS} -n ${K8S_NAMESPACE}"
                            
                            // 3. Wait for the rollout to complete
                            sh "kubectl rollout status deployment/${K8S_DEPLOYMENT_NAME} -n ${K8S_NAMESPACE} --timeout=5m"
                            
                            echo "Deployment scaled up successfully." 
                            
                        } else if (params.ACTION == 'SCALE_DOWN') {
                            echo "Scaling down deployment ${K8S_DEPLOYMENT_NAME} to ${params.TARGET_REPLICAS} replicas..."

                            // Scale Down command
                            sh "kubectl scale deployment/${K8S_DEPLOYMENT_NAME} --replicas=${params.TARGET_REPLICAS} -n ${K8S_NAMESPACE}"

                            // Wait for the shutdown
                            sh "kubectl rollout status deployment/${K8S_DEPLOYMENT_NAME} -n ${K8S_NAMESPACE} --timeout=5m"
                            
                            echo "Deployment scaled down successfully."
                        }
                    }
                }
            }
        }
    }
}
