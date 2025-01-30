# Databricks notebook source
# DBTITLE 1,Create Catalog and Schemas
# MAGIC %sql
# MAGIC
# MAGIC CREATE CATALOG IF NOT EXISTS westeurope_test_demo;
# MAGIC
# MAGIC USE CATALOG westeurope_test_demo;
# MAGIC
# MAGIC CREATE SCHEMA IF NOT EXISTS demo_schema_1;
# MAGIC
# MAGIC CREATE SCHEMA IF NOT EXISTS demo_schema_2;
# MAGIC

# COMMAND ----------

# DBTITLE 1,Cleanup
# MAGIC %sql
# MAGIC
# MAGIC DROP CATALOG IF EXISTS westeurope_test_demo CASCADE;
