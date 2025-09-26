import os
from datetime import datetime, timezone
from typing import Annotated, Any, Dict

import boto3
import httpx
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.responses import Response
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
from types_boto3_s3 import S3Client

from src.models.video_model import VideoModel

app = FastAPI()

S3_BUCKET_NAME = os.environ.get(
    "S3_BUCKET_NAME", "videos-dd9f9a31-21eb-53a3-4f05-9cb8ba6dc067"
)


class VideoContent(BaseModel):
    body: str
    id: str
    sent_time: str
    state: str
    thumbnail: str
    uri: str
    post_uri: str


def get_mrss_template() -> Jinja2Templates:
    return Jinja2Templates(directory="templates")


async def get_s3_client():
    s3_client = boto3.client("s3")
    try:
        yield s3_client
    finally:
        s3_client.close()


@app.post("/")
async def new_content_webhook(
    content: VideoContent, s3_client: Annotated[S3Client, Depends(get_s3_client)]
):
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(content.uri)
            response.raise_for_status()
            video_data = response.content

            response = await client.get(content.thumbnail)
            response.raise_for_status()
            thumbnail_data = response.content

        print(f"Downloaded video: {len(video_data)} bytes")

        video_s3_key = (
            f"videos/{content.id}_{datetime.now(timezone.utc).isoformat()}.mp4"
        )
        s3_client.put_object(
            Bucket=S3_BUCKET_NAME,
            Key=video_s3_key,
            Body=video_data,
            ContentType="video/mp4",
            Metadata={"tiktok_uri": content.post_uri},
        )

        print(f"Uploaded video to S3: {video_s3_key}")

        thumbnail_s3_key = (
            f"thumb/{content.id}_{datetime.now(timezone.utc).isoformat()}.jpg"
        )
        s3_client.put_object(
            Bucket=S3_BUCKET_NAME,
            Key=thumbnail_s3_key,
            Body=thumbnail_data,
            ContentType="image/jpeg",
            Metadata={"tiktok_uri": content.post_uri},
        )

        print(f"Uploaded thumbnail to S3: {thumbnail_s3_key}")

        sent_time_dt = datetime.fromisoformat(content.sent_time.replace("Z", "+00:00"))

        video_item = VideoModel(
            id=content.id,
            body=content.body,
            sent_time=sent_time_dt,
            state=content.state,
            tiktok_uri=content.post_uri,
            s3_thumbnail=f"https://{S3_BUCKET_NAME}.s3.amazonaws.com/{thumbnail_s3_key}",
            s3_uri=f"https://{S3_BUCKET_NAME}.s3.amazonaws.com/{video_s3_key}",
        )
        video_item.save()
        print(f"Saved video metadata to DynamoDB: {content.id}")

        return Response(status_code=status.HTTP_200_OK)

    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=400, detail=f"Error downloading video: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing video: {str(e)}")
