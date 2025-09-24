from pynamodb.attributes import (
    NumberAttribute,
    UnicodeAttribute,
    UnicodeSetAttribute,
    UTCDateTimeAttribute,
)
from pynamodb.models import Model


class SharedPostModel(Model):
    class Meta:
        table_name = "shared_post_model"
        region = "us-east-1"

    id = NumberAttribute(hash_key=True)
    body = UnicodeAttribute()
    sent_time = NumberAttribute()
