#!/bin/bash

GENCAT_SITE_DOMAIN="madrid.gobierto.test"

# Extract > Download last start query date
cd $DEV_DIR/gobierto-etl-utils/; ruby operations/download-s3/run.rb "gencat/gobierto_people/last_execution/last_start_query_date.txt" /tmp/gencat/downloads/

# cd $DEV_DIR/gobierto-etl-gencat/; ruby operations/gobierto_people/clear-path/run.rb downloads/last_start_query_date.txt
# Extract > Check data presence
cd $DEV_DIR/gobierto-etl-gencat/; ruby operations/gobierto_people/check-data-presence/run.rb all

# Extract > Clean previous downloads
cd $DEV_DIR/gobierto-etl-gencat/; ruby operations/gobierto_people/clear-path/run.rb downloads/datasets

# Extract > Download data
while read args; do
  cd $DEV_DIR/gobierto-etl-utils/; ruby operations/download/run.rb $args
done < /tmp/gencat/datasets_for_extraction
cd $DEV_DIR/gobierto-etl-utils/; ruby operations/download-s3/run.rb "gencat/gobierto_people/datasets/trips.csv" /tmp/gencat/downloads/datasets

# Transform & Load > Process resources
cd $DEV_DIR/gobierto/; bin/rails runner $DEV_DIR/gobierto-etl-gencat/operations/gobierto_people/import-events/run.rb downloads/datasets/events.csv $GENCAT_SITE_DOMAIN
cd $DEV_DIR/gobierto/; bin/rails runner $DEV_DIR/gobierto-etl-gencat/operations/gobierto_people/import-gifts/run.rb downloads/datasets/gifts.csv $GENCAT_SITE_DOMAIN
cd $DEV_DIR/gobierto/; bin/rails runner $DEV_DIR/gobierto-etl-gencat/operations/gobierto_people/import-invitations/run.rb downloads/datasets/invitations.csv $GENCAT_SITE_DOMAIN
cd $DEV_DIR/gobierto/; bin/rails runner $DEV_DIR/gobierto-etl-gencat/operations/gobierto_people/import-trips/run.rb downloads/datasets/trips.csv $GENCAT_SITE_DOMAIN

# Documentation > Upload last execution date
cd $DEV_DIR/gobierto-etl-utils/; ruby operations/upload-s3/run.rb /tmp/gencat/output/start_query_date.txt "gencat/gobierto_people/last_execution/last_start_query_date.txt"
