from totes_star_schema import format_list_to_dict_of_dataframes, pull_latest_json_from_data_bucket, \
     transform_all_tables
from pprint import pprint



"""template for future"""
def lambda_handler():
    """template for future"""    

    (data_list, table_names) = pull_latest_json_from_data_bucket()
    df_old=format_list_to_dict_of_dataframes(data_list, table_names)
    df_new=transform_all_tables(df_old)  

    print (df_new["fact_purchase_order"])

    return

lambda_handler()
