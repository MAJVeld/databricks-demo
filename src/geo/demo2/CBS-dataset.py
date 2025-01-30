# Databricks notebook source
# MAGIC %md
# MAGIC
# MAGIC # Geospatial data Databricks demo
# MAGIC
# MAGIC Contents inspired by: https://databrickslabs.github.io/mosaic/usage/kepler.html
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC **Important**: This notebook must be ran on a cluster with a Photon-enabled Databricks 13.x runtime. 

# COMMAND ----------

# MAGIC %pip install "databricks-mosaic"

# COMMAND ----------

dbutils.library.restartPython()

# COMMAND ----------

import mosaic as mos
mos.enable_mosaic(spark, dbutils)

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC # Load CBS data on neighbourhoods

# COMMAND ----------

target_path = '/Volumes/geo/demo2/input/cbs_buurt_2021.geojson'

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC # Do some basic pre-processing
# MAGIC
# MAGIC - The original geojson file is in the EPSG:28992 coordinate system and must be transformed to the WSG84 system for visualization

# COMMAND ----------

from pyspark.sql.functions import *

crs_section = named_struct(lit("type"), lit("name"), lit("properties"), named_struct(lit("name"), lit("EPSG:28992")))

all_neighbourhoods = (
  spark.read
    .option("multiline", "true")
    .format("json")
    .load(target_path)

    # Extract geoJSON values for shapes
    .select("type", explode(col("features")).alias("feature"))
    .select("type", col("feature.properties").alias("properties"), to_json(col("feature.geometry").withField("crs", crs_section)).alias("geom_json")) 

    # Transform to Mosaic internal representation and drop the original column
    .withColumn("geom_internal", mos.st_transform(mos.st_geomfromgeojson("geom_json"), lit(4326)))
    .drop("geom_json")

    # Extract some properties of interest to separate columns
    .withColumn("Gemeente", col("properties.GM_NAAM"))
    .withColumn("Buurt", col("properties.BU_NAAM"))
    .withColumn("Postcode", col("properties.POSTCODE"))
    .withColumn("Ratio_men_women", coalesce(col("properties.AANT_MAN") / col("properties.AANT_VROUW"), lit(-1))) 
)

# COMMAND ----------

display(all_neighbourhoods.limit(2))

# COMMAND ----------

filtered_df = all_neighbourhoods.where(all_neighbourhoods["Gemeente"] == "Tilburg")

# COMMAND ----------

filtered_df.select("Buurt", "ratio_men_women").display()

# COMMAND ----------

# MAGIC %%mosaic_kepler
# MAGIC filtered_df "geom_internal" "geometry"

# COMMAND ----------

from keplergl import KeplerGl

config = {
    'version': 'v1',
    'config': {
        'mapState': {
            'latitude': 51.54,
            'longitude': 5.08,
            'zoom': 12.32053899007826
        }
    }
}

map = KeplerGl(config=config)

map

# COMMAND ----------

map.config

# COMMAND ----------


