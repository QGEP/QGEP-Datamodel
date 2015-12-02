#!/bin/bash

# This script will create a clean datastructure for the QGEP project based on
# the SIA 405 datamodel.
# It will create a new schema qgep in a postgres database.
#
# Environment variables:
#
#  * PGSERVICE
#      Specifies the postgres database to be used
#        Defaults to pg_qgep
#
#      Examples:
#        export PGSERVICE=pg_qgep
#        ./db_setup.sh

# Exit on error
set -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..

if [ "0${PGSERVICE}" = "0" ]
then
  PGSERVICE=pg_qgep
fi

while getopts ":f" opt; do
  case $opt in
    f)
      force=True
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

if [[ $force ]]; then
  psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -c "DROP SCHEMA qgep CASCADE"
fi
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/00_qgep_schema.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/01_audit.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/02_oid_generation.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/03_qgep_db_dss.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/04_vsa_kek_extension.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/05_data_model_extensions.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/06_symbology_functions.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/07_views_for_network_tracking.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/08_qgep_functions.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/09_qgep_dictionaries.sql

psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -v SCHEMA=qgep -f ${DIR}/metaproject/postgresql/pg_inherited_table_view/pg_inherited_table_view.sql

psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_access_aid.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_benching.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_backflow_prevention.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_channel.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_cover.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_discharge_point.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_dryweather_downspout.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_dryweather_flume.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_manhole.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_reach.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_special_structure.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_wastewater_node.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_qgep_cover.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_qgep_reach.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/view/vw_oo_overflow.sql
