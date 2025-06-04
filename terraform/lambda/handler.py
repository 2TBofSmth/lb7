import boto3

def handler(event, context):
    s3 = boto3.client('s3', endpoint_url='http://localhost:4566')

    source_bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    target_bucket = 's3-finish'

    s3.copy_object(
        CopySource={'Bucket': source_bucket, 'Key': key},
        Bucket=target_bucket,
        Key=key
    )

    print(f"Copied {key} from {source_bucket} to {target_bucket}")
    return {"statusCode": 200}
