from pynamodb.attributes import NumberAttribute, UnicodeAttribute
from pynamodb.indexes import AllProjection, GlobalSecondaryIndex
from pynamodb.models import Model

from src.environment import AWS_REGION, DYNAMO_TABLE_NAME


class FeedTypeTimestampIndex(GlobalSecondaryIndex):
    """
    Global secondary index for querying by feed_type and sent_time
    """

    class Meta:
        index_name = "FeedTypeTimestampIndex"
        projection = AllProjection()

    feed_type = UnicodeAttribute(hash_key=True)
    sent_time = NumberAttribute(range_key=True)


class VideoModel(Model):
    """
    A DynamoDB model for storing video information
    """

    class Meta:
        table_name = DYNAMO_TABLE_NAME
        region = AWS_REGION

    id = UnicodeAttribute(hash_key=True)
    sent_time = NumberAttribute()
    body = UnicodeAttribute()
    state = UnicodeAttribute()
    tiktok_uri = UnicodeAttribute()
    s3_thumbnail = UnicodeAttribute()
    s3_uri = UnicodeAttribute()
    feed_type = UnicodeAttribute(default="main")

    feed_timestamp_index = FeedTypeTimestampIndex()
