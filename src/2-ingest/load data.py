# Databricks notebook source
# MAGIC %md
# MAGIC Load configuration

# COMMAND ----------

# MAGIC %run ../includes/configuration

# COMMAND ----------

# MAGIC %md
# MAGIC # Load data
# MAGIC
# MAGIC Load a sample data set available by default inside Databricks

# COMMAND ----------

# MAGIC %md 
# MAGIC
# MAGIC ## List available data files

# COMMAND ----------

source_path = 'dbfs:/databricks-datasets/nyctaxi/tripdata/yellow/'

# COMMAND ----------

display(dbutils.fs.ls(source_path))

# COMMAND ----------

file_name = 'yellow_tripdata_2019-12.csv.gz'

# COMMAND ----------

# MAGIC %md 
# MAGIC ## Load single data file into Spark Data Frame

# COMMAND ----------

from pyspark.sql.functions import col, lit, expr, when
from pyspark.sql.types import *
from datetime import datetime
import time
 
# Define schema
nyc_schema = StructType([
  StructField('Vendor', StringType(), True),
  StructField('Pickup_DateTime', TimestampType(), True),
  StructField('Dropoff_DateTime', TimestampType(), True),
  StructField('Passenger_Count', IntegerType(), True),
  StructField('Trip_Distance', DoubleType(), True),
  StructField('Pickup_Longitude', DoubleType(), True),
  StructField('Pickup_Latitude', DoubleType(), True),
  StructField('Rate_Code', StringType(), True),
  StructField('Store_And_Forward', StringType(), True),
  StructField('Dropoff_Longitude', DoubleType(), True),
  StructField('Dropoff_Latitude', DoubleType(), True),
  StructField('Payment_Type', StringType(), True),
  StructField('Fare_Amount', DoubleType(), True),
  StructField('Surcharge', DoubleType(), True),
  StructField('MTA_Tax', DoubleType(), True),
  StructField('Tip_Amount', DoubleType(), True),
  StructField('Tolls_Amount', DoubleType(), True),
  StructField('Total_Amount', DoubleType(), True)
])

rawDF = (spark
    .read
    .format('csv')
    .options(header=True)
    .schema(nyc_schema)
    .load(f"{source_path}{file_name}"))
 

# COMMAND ----------

# MAGIC %md
# MAGIC ## Show contents and schema
# MAGIC Display the contents of the top 10 row as present in the dataframe and display the schema of the dataframe afterwards

# COMMAND ----------

rawDF.show(10)

# COMMAND ----------

rawDF.printSchema()

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC ## Contents of the table
# MAGIC Since the dataframe has not yet been persisted to the delta table, it is empty and no selection can be made from it.

# COMMAND ----------

# MAGIC %sql
# MAGIC
# MAGIC DECLARE OR REPLACE VARIABLE full_table_name string = 'demo2.nyctaxi.taxidata'

# COMMAND ----------

# MAGIC %sql
# MAGIC
# MAGIC SELECT * FROM IDENTIFIER(full_table_name)

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC ## Write contents of dataframe to delta table
# MAGIC
# MAGIC Persist data to the delta table and show the record count after saving in the next notebook cell.

# COMMAND ----------

rawDF.write.mode("overwrite").option("mergeSchema", True).saveAsTable(full_table_name)

# COMMAND ----------

# MAGIC %sql
# MAGIC
# MAGIC SELECT count(1) AS NumberOfRecords
# MAGIC FROM IDENTIFIER(full_table_name)

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC ## Examine the stored contents in the storage account
# MAGIC The code below shows that the delta table consists of one or more parquet files and a `_delta_log` folder containing the  metadata

# COMMAND ----------

display(dbutils.fs.ls(delta_path))

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC ## Some further data selection
# MAGIC The code below demonstrates some made up selection of columns from the data stored in the delta table. The cleaned and selected data is then saved to the `nyctaxi.taxidata_cleaned` table.

# COMMAND ----------

from pyspark.sql.functions import unix_timestamp, month, year, to_date

# COMMAND ----------

columns = ["Vendor", "Pickup_Date", "Passenger_Count", "Trip_Distance", "Duration", "Tip_Amount"]

processedDF = (spark.read.table(full_table_name)
.withColumn('Duration', unix_timestamp("DropOff_DateTime") - unix_timestamp("Pickup_DateTime"))
.withColumn('Pickup_Date', to_date("Pickup_DateTime", "YYYY-MM-dd"))
.withColumn('Year', year("Pickup_DateTime").cast("integer"))
.withColumn('Month', month("Pickup_DateTime").cast("integer"))
.filter((col("Year") == 2019) & (col("Month") == 12))
.select(*columns))

# COMMAND ----------

processedDF.write.mode("overwrite").option("mergeSchema", True).saveAsTable(full_table_name_cleaned)

# COMMAND ----------

processedDF.show(10)

# COMMAND ----------

display(spark.sql(f"SELECT count(1) AS NumberOfRecords FROM {full_table_name_cleaned}"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Sample data selection and visualization
# MAGIC The code below shows that data can be read from the cleaned table and can be used for visualization in the Databricks UI.

# COMMAND ----------

display(spark.sql(f"""
SELECT Vendor, Pickup_Date, avg(Passenger_Count) AS Average_Passengers 
FROM {full_table_name_cleaned}
WHERE Vendor is NOT NULL
GROUP BY Vendor, Pickup_Date
ORDER BY Vendor, Pickup_Date ASC
"""))

# COMMAND ----------


