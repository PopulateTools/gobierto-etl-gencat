#!/bin/bash

GENCAT_SITE_DOMAIN="madrid.gobierto.test"
LAYOUT_LOCATION="http://governobert.gencat.cat/templates?mode=html&code=GOOB0001"
GENCAT_ETL=$DEV_DIR/gobierto-etl-gencat
STORAGE_DIR=$DEV_DIR/gobierto-etl-gencat/tmp

# Extract > Download layout file
wget -O $STORAGE_DIR/layouts_application.html $LAYOUT_LOCATION

# Transform > Insert custom tags
cd $GENCAT_ETL; ruby operations/import_custom_layout/generate_template.rb $STORAGE_DIR/layouts_application.html $STORAGE_DIR/layouts_application.html.erb

# Load > Update site template
cd $DEV_DIR/gobierto; bin/rails runner $GENCAT_ETL/operations/import_custom_layout/load_template.rb $GENCAT_SITE_DOMAIN $STORAGE_DIR/layouts_application.html.erb
