"""lambda_handler for handling uploading processed S3 Bucket data
    to our data warehouse"""
import logging
from .helpers import get_secret, connect_to_db, process_gzip_file

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# pylint: disable=unused-argument
def lambda_handler(event, context):
    """Lambda function that retrieves secrets from AWS, uses them to connect
    to our data warehouse, connects to a processed s3 bucket, and uploads
    the processed data"""

    logger.info("Lambda function started")

    try:
        secret = get_secret("DataWarehouse")

        db_credentials = {
            "cohort_id": secret["cohort_id"],
            "user": secret["user"],
            "password": secret["password"],
            "host": secret["host"],
            "database": secret["database"],
            "port": secret["port"],
            "schema": secret["schema"]
        }

        connection = connect_to_db(db_credentials)

        for record in event['Records']:
            bucket_name = record['s3']['bucket']['name']
            object_key = record['s3']['object']['key']
            process_gzip_file(connection, bucket_name, object_key, db_credentials)

        logger.info("All files processed successfully.")
        return {
            'statusCode': 200,
            'body': 'Files processed successfully.'
        }
    except Exception as e:
        logger.error("Error processing event: %s", e)
        raise
