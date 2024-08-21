"""Script for lambda_handler"""

import datetime
import boto3
from crud_functions import fetch_all_tables
from utils.get_bucket_names import get_data_bucket_name
from utils.json_io import save_json

def lambda_handler():

    """lambda function to put zip on S3 Bucket"""

    full_data = fetch_all_tables()
    full_data_json = save_json(full_data)
    bucket_name = get_data_bucket_name()

    s3 = boto3.client('s3', region_name='eu-west-2')
    
    s3.put_object(
        Body=full_data_json,
        Bucket=bucket_name,
        Key=f'{datetime.datetime.now().year}/{datetime.datetime.strptime(f"{datetime.datetime.now().month}", "%m").strftime("%B")}/{datetime.datetime.now().day}/{datetime.datetime.now().strftime('%H:%M:%S')}_db_totes.json'
    )

    s3.put_object(
        Body=full_data_json,
        Bucket=bucket_name,
        Key='latest_db_totes.json'
    )

if __name__ == '__main__':
    lambda_handler()
    with open('./db/json_files/zzz_db_totesys.json', 'w', encoding='utf-8') as f:
        f.write(save_json(fetch_all_tables()))
