from typing import Annotated, Any, Dict

import boto3
import httpx
from fastapi import Depends, FastAPI, Request
from fastapi.responses import Response
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
from types_boto3_s3 import S3Client

app = FastAPI()


class VideoContent(BaseModel):
    body: str
    id: str
    sent_time: str
    state: str
    thumbnail: str
    uri: str


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
    """Root endpoint that downloads video and processes content"""

    async with httpx.AsyncClient() as client:
        response = await client.get(content.uri)
        response.raise_for_status()
        video_data = response.content

    print(f"Downloaded video: {len(video_data)} bytes")

    return content
