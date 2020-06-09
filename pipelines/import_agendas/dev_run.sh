#!/bin/bash

GENCAT_SITE_DOMAIN="gencat.gobierto.test"
CLEAR_PREVIOUS_DATA="True"
RAILS_ENV="development"
WORKING_DIR=/tmp/gencat

# Extract > Download last start query date
cd $DEV_DIR/gobierto-etl-utils/; ruby operations/download-s3/run.rb "gencat/gobierto_people/last_execution/last_start_query_date-$RAILS_ENV.txt" $WORKING_DIR/downloads/

# cd $DEV_DIR/gobierto-etl-gencat/; ruby operations/gobierto_people/clear-path/run.rb downloads/last_start_query_date-$RAILS_ENV.txt
# Extract > Clear previous data
if $CLEAR_PREVIOUS_DATA; then
  cd $DEV_DIR/gobierto/; bin/rails runner $DEV_DIR/gobierto-etl-gencat/operations/gobierto_people/clear-previous-data/run.rb $GENCAT_SITE_DOMAIN
fi

# # Extract > Check data presence
if $CLEAR_PREVIOUS_DATA; then
  cd $DEV_DIR/gobierto-etl-gencat/; ruby operations/gobierto_people/check-data-presence/run.rb $RAILS_ENV all forever
else
  cd $DEV_DIR/gobierto-etl-gencat/; ruby operations/gobierto_people/check-data-presence/run.rb $RAILS_ENV all
fi

# Extract > Clean previous downloads
cd $DEV_DIR/gobierto-etl-gencat/; ruby operations/gobierto_people/clear-path/run.rb downloads/datasets

# Extract > Download data
while read args; do
  cd $DEV_DIR/gobierto-etl-utils/; ruby operations/download/run.rb $args
done < $WORKING_DIR/datasets_for_extraction

# Transform > Convert charges csv to UTF8
cd $DEV_DIR/gobierto-etl-utils/; ruby operations/convert-to-utf8/run.rb ${WORKING_DIR}/downloads/datasets/charges.csv ${WORKING_DIR}/downloads/datasets/charges_utf8.csv ISO-8859-1

# Transform & Load > Process resources
# For the moment charges dataset must be downloaded manually (https://github.com/PopulateTools/issues/issues/1028)
cd $DEV_DIR/gobierto/; bin/rails runner $DEV_DIR/gobierto-etl-gencat/operations/gobierto_people/import-charges/run.rb downloads/datasets/charges_utf8.csv $GENCAT_SITE_DOMAIN
cd $DEV_DIR/gobierto/; bin/rails runner $DEV_DIR/gobierto-etl-gencat/operations/gobierto_people/import-gifts/run.rb downloads/datasets/gifts.csv $GENCAT_SITE_DOMAIN
cd $DEV_DIR/gobierto/; bin/rails runner $DEV_DIR/gobierto-etl-gencat/operations/gobierto_people/import-invitations/run.rb downloads/datasets/invitations.csv $GENCAT_SITE_DOMAIN
cd $DEV_DIR/gobierto/; bin/rails runner $DEV_DIR/gobierto-etl-gencat/operations/gobierto_people/import-trips/run.rb downloads/datasets/trips.csv $GENCAT_SITE_DOMAIN
cd $DEV_DIR/gobierto/; bin/rails runner $DEV_DIR/gobierto-etl-gencat/operations/gobierto_people/import-events/run.rb downloads/datasets/events.csv $GENCAT_SITE_DOMAIN

# Upload trips to S3 for CARTO
cd $DEV_DIR/gobierto; bin/rails runner $DEV_DIR/gobierto-etl-gencat/operations/gobierto_people/export-trips/run.rb $GENCAT_SITE_DOMAIN gencat_trips_$RAILS_ENV.csv
cd $DEV_DIR/gobierto-etl-utils/; ruby operations/upload-s3/run.rb $WORKING_DIR/gencat_trips_$RAILS_ENV.csv gencat/gobierto_people/gencat_trips_$RAILS_ENV.csv

# Documentation > Upload last execution date
cd $DEV_DIR/gobierto-etl-utils/; ruby operations/upload-s3/run.rb /tmp/gencat/output/start_query_date.txt "gencat/gobierto_people/last_execution/last_start_query_date-$RAILS_ENV.txt"

# Clear cache
cd $DEV_DIR/gobierto-etl-utils/; ruby operations/gobierto/clear-cache/run.rb
