#!/bin/bash

set -e

GENCAT_SITE_DOMAIN="madrid.gobierto.test"
LAYOUT_LOCATION="https://governobert.gencat.cat/templates?mode=html&code=GOOB0001"
GENCAT_ETL=$DEV_DIR/gobierto-etl-gencat
STORAGE_DIR=$DEV_DIR/gobierto-etl-gencat/tmp
LOCALES="ca es"

# Extract > Download layout file
cd $GENCAT_ETL; ruby operations/import_custom_layout/download_layout.rb $STORAGE_DIR $LAYOUT_LOCATION $LOCALES

# Transform > Insert custom tags
cd $GENCAT_ETL; ruby operations/import_custom_layout/generate_template.rb $STORAGE_DIR/downloaded_layout_ca.html $STORAGE_DIR/layouts_application_ca.html.erb
cd $GENCAT_ETL; ruby operations/import_custom_layout/generate_template.rb $STORAGE_DIR/downloaded_layout_es.html $STORAGE_DIR/layouts_application_es.html.erb

# Transform > Merge templates
cd $GENCAT_ETL; ruby operations/import_custom_layout/merge_templates.rb $STORAGE_DIR $LOCALES

# Load > Update site template
cd $DEV_DIR/gobierto; bin/rails runner $GENCAT_ETL/operations/import_custom_layout/load_template.rb $GENCAT_SITE_DOMAIN $STORAGE_DIR/layouts_application.html.erb
