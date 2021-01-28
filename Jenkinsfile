
def defaultConfig = {
    nodeLabel = defaultNodeLabel()
    slackChannel = ''
    slackAlwaysNotify = true
}

def config = jobConfig(defaultConfig)

def job = {
    stage("Startup") {
        withDockerServer([uri: dockerHost()]) {
            writeFile file:'extract-iam-credential.sh', text:libraryResource('scripts/extract-iam-credential.sh')
            sh '''
                bash extract-iam-credential.sh

                # Hide login credential from below
                set +x

                LOGIN_CMD=$(aws ecr get-login --no-include-email --region us-west-2)
                $LOGIN_CMD
            '''
            try {
                sh '''
                    export REPOSITORY=368821881613.dkr.ecr.us-west-2.amazonaws.com/confluentinc
                    ./scripts/start.sh
                '''
            } finally {
                sh '''docker-compose logs zookeeper'''
                sh '''netstat -ltnp | grep -w ":2181"'''
                sh '''lsof -i :2181''' 
            }
        }
    }

    return null
}

def post = {
    message = null
    return message
}

runJob config, job, post
