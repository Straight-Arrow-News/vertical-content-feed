import json
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

from models.video_model import VideoModel

app = FastAPI()

S3_BUCKET_NAME = os.environ.get("S3_BUCKET_NAME", "videos")


class VideoContent(BaseModel):
    body: str
    id: str
    sent_time: str
    state: str
    s3_thumbnail: str
    s3_uri: str


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
            response = await client.get(content.s3_uri)
            response.raise_for_status()
            video_data = response.content

        print(f"Downloaded video: {len(video_data)} bytes")

        # Upload video to S3
        s3_key = f"videos/{content.id}_{datetime.now(timezone.utc).isoformat()}.mp4"
        s3_client.put_object(
            Bucket=S3_BUCKET_NAME, Key=s3_key, Body=video_data, ContentType="video/mp4"
        )
        print(f"Uploaded video to S3: {s3_key}")

        # # Save metadata to DynamoDB
        # video_item = VideoModel(
        #     id=content.id,
        #     body=content.body,
        #     sent_time=content.sent_time,
        #     state=content.state,
        #     s3_thumbnail=content.s3_thumbnail,
        #     s3_uri=f"s3://{S3_BUCKET_NAME}/{s3_key}",
        #     created_at=datetime.now(timezone.utc),
        # )
        # video_item.save()
        # print(f"Saved video metadata to DynamoDB: {content.id}")

        return Response(status_code=status.HTTP_200_OK)

    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=400, detail=f"Error downloading video: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing video: {str(e)}")
