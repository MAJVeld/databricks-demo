# Databricks notebook source
# MAGIC %md
# MAGIC # Load configuration

# COMMAND ----------

# MAGIC %run ../includes/configuration
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC # Remove data from previous demo
# MAGIC
# MAGIC Remove data from previous demo. 
# MAGIC Since this is an external delta table, the underlying data files must be manually removed from the storage account in addition to the metadata in Unity Catalog

# COMMAND ----------

spark.sql(f"DROP TABLE IF EXISTS {full_table_name};")
spark.sql(f"DROP TABLE IF EXISTS {full_table_name_cleaned};")

# COMMAND ----------

dbutils.fs.rm(delta_path, recurse=True)
dbutils.fs.rm(delta_path_cleaned, recurse=True)

# COMMAND ----------

spark.sql(f"DROP CATALOG IF EXISTS {catalog_name} CASCADE;")

# COMMAND ----------


