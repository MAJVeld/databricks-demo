# Databricks notebook source
# Configuration parameters
prefix = "mv"
name = "demo"
location_short = "weu"

raw_container_name = "raw"
delta_table_container_name = "delta"

catalog_name = 'demo';
schema_name = 'nyctaxi';
table_name = 'taxidata';

data_path_name = "nyctaxi"

# storage account and folder related configuration
storageaccount_name = f'{prefix}{name}sa{location_short}'

external_raw_location = f'abfss://{raw_container_name}@{storageaccount_name}.dfs.core.windows.net'
external_delta_location = f'abfss://{delta_table_container_name}@{storageaccount_name}.dfs.core.windows.net'

delta_path = f'{external_delta_location}/{table_name}'
delta_path_cleaned = f'{external_delta_location}/{table_name}_cleaned'

# catalog and schema related configuration
full_schema_name = f'{catalog_name}.{schema_name}'
full_table_name = f'{catalog_name}.{schema_name}.{table_name}'
full_table_name_cleaned = f'{catalog_name}.{schema_name}.{table_name}_cleaned'
