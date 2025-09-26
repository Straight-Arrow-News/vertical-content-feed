import os

S3_BUCKET_NAME = os.environ.get(
    "S3_BUCKET_NAME", "videos-dd9f9a31-21eb-53a3-4f05-9cb8ba6dc067"
)

AWS_REGION = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")


DYNAMO_TABLE_NAME = os.environ.get("VIDEOS_TABLE_NAME", "videos")
