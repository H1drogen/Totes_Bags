"""A collection of helper functions"""
import json
import gzip
import io
import logging
import pg8000
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_secret(secret_name):
    """A function that gets secrets from AWS for our lambda function"""
    secrets_client = boto3.client('secretsmanager')
    response = secrets_client.get_secret_value(SecretId=secret_name)
    secret_string = response['SecretString']
    return json.loads(secret_string)

def connect_to_db(credentials):
    """Function that handles connection"""
    try:
        connection = pg8000.connect(
            user=credentials['user'],
            password=credentials['password'],
            host=credentials['host'],
            port=credentials['port'],
            database=credentials['database'],
        )
        return connection
    except Exception as e:
        logger.error("Error connecting to the database: %s", e)
        raise

def process_gzip_file(connection, bucket_name, object_key, credentials):
    """Function that gets files from Processed s3 Bucket and uses gzip
        to bring it into the insert function"""
    s3_client = boto3.client('s3')
    try:
        s3_object = s3_client.get_object(Bucket=bucket_name, Key=object_key)
        with gzip.GzipFile(fileobj=io.BytesIO(s3_object['Body'].read())) as gzipfile:
            content = gzipfile.read().decode('utf-8')
        table_name = determine_table_name(object_key)
        if table_name:
            logger.info("Inserting data into table %s", table_name)
            insert_data_into_db(connection, content, credentials['schema'], table_name)
        else:
            logger.warning("Unrecognized file %s. Skipping.", object_key)

    except Exception as e:
        logger.error("Error processing file %s from bucket %s: %s", object_key, bucket_name, e)
        raise

def determine_table_name(object_key):
    """Helper function within the helper function. Assists process_gzip_file
        with finding the name of the table to be used in insert_data_into_db"""
    file_table_map = {
        "fact_sales_order.gzip": "fact_sales_order",
        "fact_purchase_orders.gzip": "fact_purchase_orders",
        "fact_payment.gzip": "fact_payment",
        "dim_transaction.gzip": "dim_transaction",
        "dim_staff.gzip": "dim_staff",
        "dim_payment_type.gzip": "dim_payment_type",
        "dim_location.gzip": "dim_location",
        "dim_design.gzip": "dim_design",
        "dim_date.gzip": "dim_date",
        "dim_currency.gzip": "dim_currency",
        "dim_counterparty.gzip": "dim_counterparty"
    }
    return file_table_map.get(object_key)

def insert_data_into_db(connection, content, schema, table_name):
    """Function for inserting to our Data Warehouse"""
    cursor = connection.cursor()
    try:
        insert_query = f"INSERT INTO {schema}.{table_name} (column1, column2) VALUES (%s, %s)"

        data = content.splitlines()
        for row in data:
            values = row.split(',')
            cursor.execute(insert_query, values)
        connection.commit()
        logger.info("Data successfully inserted into table %s", table_name)
    except Exception as e:
        logger.error("Error inserting data into table %s: %s", table_name, e)
        connection.rollback()
        raise
    finally:
        cursor.close()
