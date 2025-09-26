from datetime import datetime, timezone
from typing import Annotated, List
from urllib.parse import quote_plus

import boto3
import httpx
from fastapi import Depends, FastAPI, Header, HTTPException, Request, status
from fastapi.responses import Response
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
from types_boto3_s3 import S3Client

from .environment import AWS_REGION, FEED_URL, S3_BUCKET_NAME, ZAPIER_SECRET_KEY
from .models.video_model import VideoModel

app = FastAPI()


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
    content: VideoContent,
    s3_client: Annotated[S3Client, Depends(get_s3_client)],
    x_secret_key: Annotated[str | None, Header()] = None,
):
    if not ZAPIER_SECRET_KEY or x_secret_key != ZAPIER_SECRET_KEY:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

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
        s3_uri = "https://s3.{0}.amazonaws.com/{1}/{2}".format(
            AWS_REGION, S3_BUCKET_NAME, quote_plus(video_s3_key)
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

        thumbnail_uri = "https://s3.{0}.amazonaws.com/{1}/{2}".format(
            AWS_REGION, S3_BUCKET_NAME, quote_plus(thumbnail_s3_key)
        )

        print(f"Uploaded thumbnail to S3: {thumbnail_s3_key}")

        sent_time_dt = datetime.fromisoformat(
            content.sent_time.replace("Z", "+00:00")
        ).timestamp()

        video_item = VideoModel(
            id=content.id,
            body=content.body,
            sent_time=sent_time_dt,
            state=content.state,
            tiktok_uri=content.post_uri,
            s3_thumbnail=thumbnail_uri,
            s3_uri=s3_uri,
            feed_type="main",
        )
        video_item.save()
        print(f"Saved video metadata to DynamoDB: {content.id}")

        return Response(status_code=status.HTTP_200_OK)

    except httpx.HTTPError as e:
        print(e)
        raise HTTPException(status_code=400)
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500)


@app.get("/")
async def get_video_feed(
    request: Request,
    templates: Annotated[Jinja2Templates, Depends(get_mrss_template)],
):
    try:
        videos: List[VideoModel] = []
        for video in VideoModel.feed_timestamp_index.query(
            "main",
            scan_index_forward=False,
            limit=20,
        ):
            videos.append(video)

        items = []
        for video in videos[:20]:
            sent_time_dt = datetime.fromtimestamp(video.sent_time, tz=timezone.utc)
            items.append(
                {
                    "body": video.body,
                    "guid": video.id,
                    "pubdate": sent_time_dt.strftime("%a, %d %b %Y %H:%M:%S %z"),
                    "link": video.tiktok_uri,
                    "video_url": video.s3_uri,
                    "thumbnail_url": video.s3_thumbnail,
                }
            )

        template_response = templates.TemplateResponse(
            "mrss.j2", {"request": request, "feed_url": FEED_URL, "items": items}
        )

        return Response(
            content=template_response.body,
        )
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Error fetching video feed: {str(e)}"
        )
