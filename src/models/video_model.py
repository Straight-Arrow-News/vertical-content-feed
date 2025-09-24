import os
from datetime import datetime, timezone

from pynamodb.attributes import NumberAttribute, UnicodeAttribute, UTCDateTimeAttribute
from pynamodb.models import Model


class VideoModel(Model):
    """
    A DynamoDB model for storing video information
    """

    class Meta:
        table_name = os.environ.get("VIDEOS_TABLE_NAME", "videos")
        region = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")

    id = UnicodeAttribute(hash_key=True)
    body = UnicodeAttribute()
    sent_time = UTCDateTimeAttribute()
    state = UnicodeAttribute()
    s3_thumbnail = UnicodeAttribute()
    s3_uri = UnicodeAttribute()
