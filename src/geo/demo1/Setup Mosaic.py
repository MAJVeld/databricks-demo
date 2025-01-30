# Databricks notebook source
# MAGIC %md
# MAGIC
# MAGIC # General geospatial data Databricks demo
# MAGIC
# MAGIC Contents based on: https://databrickslabs.github.io/mosaic/usage/kepler.html
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

from pyspark.sql.functions import *
from mosaic import enable_mosaic

enable_mosaic(spark, dbutils)

# COMMAND ----------

# MAGIC %md 
# MAGIC ## Check if mosaic functions are registered

# COMMAND ----------

# MAGIC %sql
# MAGIC
# MAGIC USE CATALOG geo;

# COMMAND ----------

spark.sql("""SHOW FUNCTIONS""").where("startswith(function, 'st_')").display()

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC # Download sample data

# COMMAND ----------

import requests

target_path = '/Volumes/geo/demo1/input/nyc_taxi_zones.geojson'
req = requests.get('https://raw.githubusercontent.com/smriti283/Datasets/main/NYC_Taxi_Zones.geojson')
with open(target_path, 'wb') as f:
  f.write(req.content)


# COMMAND ----------

# MAGIC %fs
# MAGIC
# MAGIC ls /Volumes/geo/demo1/input

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC # Do some basic processing

# COMMAND ----------

from pyspark.sql.functions import *

all_neighbourhoods = (
  spark.read
    .option("multiline", "true")
    .format("json")
    .load(target_path)

    # Extract geoJSON values for shapes
    .select("type", explode(col("features")).alias("feature"))
    .select("type", col("feature.properties").alias("properties"), to_json(col("feature.geometry")).alias("geom_json"))

    # Mosaic internal representation
    .withColumn("geom_internal", mos.st_geomfromgeojson("geom_json"))
    .drop("geom_json")
)

display(all_neighbourhoods)

# COMMAND ----------

neighbourhoods = all_neighbourhoods.limit(1)

# COMMAND ----------

# MAGIC %%mosaic_kepler
# MAGIC neighbourhoods "geom_internal" "geometry"

# COMMAND ----------

neighbourhoods.createOrReplaceTempView("temp_view_neighbourhoods")

# COMMAND ----------

# MAGIC %%mosaic_kepler
# MAGIC "temp_view_neighbourhoods" "geom_internal" "geometry"

# COMMAND ----------

neighbourhood_chips = (neighbourhoods
                       .select(mos.grid_tessellateexplode("geom_internal", lit(9), False))
                       .select("index.*")
                    )

display(neighbourhood_chips)

# COMMAND ----------

# MAGIC %%mosaic_kepler
# MAGIC neighbourhood_chips "index_id" "h3"

# COMMAND ----------


