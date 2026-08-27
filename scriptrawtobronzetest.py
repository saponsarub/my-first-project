import sys

from pyspark.context import SparkContext
from pyspark.sql import functions as F
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions


# ============================================================
# 1. Glue Job Configuration
# ============================================================

args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "SOURCE_PATH",
        "TARGET_PATH"
    ]
)

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

job = Job(glueContext)
job.init(args["JOB_NAME"], args)

source_path = args["SOURCE_PATH"]
target_path = args["TARGET_PATH"]

df = (
    spark.read
    .option("header", "true")
    .option("inferSchema", "false")
    .csv(source_path)
)
df = df.withColumn(
    "ingestion_timestamp",
    F.current_timestamp()
)


(
    df.write
    .mode("append")
    .format("parquet")
    .option("compression", "snappy")
    .save(target_path)
)

job.commit()