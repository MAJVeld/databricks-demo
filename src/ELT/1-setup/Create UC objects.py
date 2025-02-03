# Databricks notebook source
# MAGIC %md
# MAGIC # Load configuration

# COMMAND ----------

# MAGIC %run "../includes/configuration"

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC ## Create storage credential (manual step)
# MAGIC The storage credential is stored in Unity Catalog and can be used to access a container or path stored as defined in an external location persisted to Unity Catalog.
# MAGIC
# MAGIC Please make sure that a correctly configured storage credential and associated external locations are added to Unity Catalog.
# MAGIC
# MAGIC For more information on external locations and storage credentials in Azure see: [link](https://learn.microsoft.com/en-us/azure/databricks/sql/language-manual/sql-ref-external-locations)

# COMMAND ----------

# MAGIC %sql
# MAGIC
# MAGIC SHOW EXTERNAL LOCATIONS

# COMMAND ----------

# MAGIC %md
# MAGIC ## Create Catalog and Schema
# MAGIC Create Catalog and schema if these do not exist yet in Unity Catalog

# COMMAND ----------

spark.sql(f"CREATE CATALOG IF NOT EXISTS {catalog_name} COMMENT 'Catalog for demo purposes';")
spark.sql(f"CREATE SCHEMA IF NOT EXISTS {full_schema_name} COMMENT 'Sample New York Taxi dataset';")


# COMMAND ----------

# MAGIC %md
# MAGIC ## Create tables

# COMMAND ----------

spark.sql(f"""
CREATE TABLE IF NOT EXISTS {full_table_name}
USING DELTA COMMENT 'New York sample data set'
LOCATION '{delta_path}';""")

# COMMAND ----------

spark.sql(f"""
CREATE TABLE IF NOT EXISTS {full_table_name}_cleaned
USING DELTA COMMENT 'New York sample data set'
LOCATION '{delta_path_cleaned}';""")

# COMMAND ----------


