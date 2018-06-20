#!/bin/bash

# Extract > Download last start query date
cd ~/proyectos/populate/gobierto_etl/gobierto-etl-utils/; ruby operations/download-s3/run.rb "gencat/gobierto_people/last_execution/last_start_query_date.txt" /tmp/gencat/downloads/

# cd ~/proyectos/populate/gobierto_etl/gobierto-etl-gencat/; ruby operations/gobierto_people/clear-path/run.rb downloads/last_start_query_date.txt
# Extract > Check data presence
cd ~/proyectos/populate/gobierto_etl/gobierto-etl-gencat/; ruby operations/gobierto_people/check-data-presence/run.rb all

# Extract > Clean previous downloads
cd ~/proyectos/populate/gobierto_etl/gobierto-etl-gencat/; ruby operations/gobierto_people/clear-path/run.rb downloads/datasets

# Extract > Download data
while read args; do
  cd ~/proyectos/populate/gobierto_etl/gobierto-etl-utils/; ruby operations/download/run.rb $args
done < /tmp/gencat/datasets_for_extraction
cd ~/proyectos/populate/gobierto_etl/gobierto-etl-utils/; ruby operations/download-s3/run.rb "gencat/gobierto_people/datasets/trips.csv" /tmp/gencat/downloads/datasets

# Transform > Download file of confict names resolutions
cd ~/proyectos/populate/gobierto_etl/gobierto-etl-utils/; ruby operations/download-s3/run.rb "gencat/gobierto_people/names_conflict_resolutions.yml" /tmp/gencat/downloads

# Transform & Load > Process resources
  cd ~/gobierto/; ~/.rvm/bin/rvm in ~/gobierto/ do bundle exec bin/rails runner ~/proyectos/populate/gobierto_etl/gobierto-etl-gencat/operations/gobierto_people/import-events/run.rb downloads/datasets/events.csv madrid.gobierto.test
  cd ~/gobierto/; ~/.rvm/bin/rvm in ~/gobierto/ do bundle exec bin/rails runner ~/proyectos/populate/gobierto_etl/gobierto-etl-gencat/operations/gobierto_people/import-gifts/run.rb downloads/datasets/gifts.csv madrid.gobierto.test
  cd ~/gobierto/; ~/.rvm/bin/rvm in ~/gobierto/ do bundle exec bin/rails runner ~/proyectos/populate/gobierto_etl/gobierto-etl-gencat/operations/gobierto_people/import-invitations/run.rb downloads/datasets/invitations.csv madrid.gobierto.test
  cd ~/gobierto/; ~/.rvm/bin/rvm in ~/gobierto/ do bundle exec bin/rails runner ~/proyectos/populate/gobierto_etl/gobierto-etl-gencat/operations/gobierto_people/import-trips/run.rb downloads/datasets/trips.csv madrid.gobierto.test

# Documentation > Upload last execution date
cd ~/proyectos/populate/gobierto_etl/gobierto-etl-utils/; ruby operations/upload-s3/run.rb /tmp/gencat/output/start_query_date.txt "gencat/gobierto_people/last_execution/last_start_query_date.txt"
