email = "popu-servers+jenkins@populate.tools "
pipeline {
    agent any
    environment {
        PATH = "/home/ubuntu/.rbenv/shims:$PATH"
        GOBIERTO_ETL_UTILS = "/var/www/gobierto-etl-utils/current"
        GENCAT_ETL = "/var/www/gobierto-etl-gencat/current"
        GOBIERTO = "/var/www/gobierto/current"
    }
    stages {
        stage('Extract > Download last start query date') {
            steps {
                sh "cd ${GOBIERTO_ETL_UTILS}; ruby operations/download-s3/run.rb 'gencat/gobierto_people/last_execution/last_start_query_date.txt' /tmp/gencat/downloads"
            }
        }
        stage('Extract > Check data presence') {
            steps {
                sh "cd ${GENCAT_ETL}; ruby operations/gobierto_people/check-data-presence/run.rb all"
            }
        }
        stage('Extract > Clean previous downloads') {
            steps {
                sh "cd ${GENCAT_ETL}; ruby operations/gobierto_people/clear-path/run.rb downloads/datasets"
            }
        }
        stage('Extract > Download data') {
            steps {
                sh "while read args; do cd ${GOBIERTO_ETL_UTILS}; ruby operations/download/run.rb \$args; done < /tmp/gencat/datasets_for_extraction"
                sh "cd ${GOBIERTO_ETL_UTILS}; ruby operations/download-s3/run.rb 'gencat/gobierto_people/datasets/trips.csv' /tmp/gencat/downloads/datasets"
            }
        }
        stage('Transform > Download file of confict names resolutions') {
            steps {
                sh "cd ${GOBIERTO_ETL_UTILS}; ruby operations/download-s3/run.rb 'gencat/gobierto_people/names_conflict_resolutions.yml' /tmp/gencat/downloads"
            }
        }
        stage('Transform & Load > Process resources') {
            steps {
                sh "cd ${GOBIERTO}; bin/rails runner ${GENCAT_ETL}/operations/gobierto_people/import-events/run.rb downloads/datasets/events.csv gencat.gobify.net"
                sh "cd ${GOBIERTO}; bin/rails runner ${GENCAT_ETL}/operations/gobierto_people/import-gifts/run.rb downloads/datasets/gifts.csv gencat.gobify.net"
                sh "cd ${GOBIERTO}; bin/rails runner ${GENCAT_ETL}/operations/gobierto_people/import-invitations/run.rb downloads/datasets/invitations.csv gencat.gobify.net"
                sh "cd ${GOBIERTO}; bin/rails runner ${GENCAT_ETL}/operations/gobierto_people/import-trips/run.rb downloads/datasets/trips.csv gencat.gobify.net"
            }
        }
        stage('Documentation > Upload last execution date') {
            steps {
                sh "cd ${GOBIERTO_ETL_UTILS}; ruby operations/upload-s3/run.rb /tmp/gencat/output/start_query_date.txt 'gencat/gobierto_people/last_execution/last_start_query_date.txt'"
            }
        }
    }
    post {
        failure {
            echo 'This will run only if failed'
            mail body: "Project: ${env.JOB_NAME} - Build Number: ${env.BUILD_NUMBER} - URL de build: ${env.BUILD_URL}",
                charset: 'UTF-8',
                subject: "ERROR CI: Project name -> ${env.JOB_NAME}",
                to: email
        }
    }
}
