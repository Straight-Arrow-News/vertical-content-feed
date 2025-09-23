from typing import Any, Dict

from fastapi import Depends, FastAPI
from fastapi.responses import Response
from fastapi.templating import Jinja2Templates

app = FastAPI()


def get_mrss_template() -> Jinja2Templates:
    return Jinja2Templates(directory="templates")


@app.get("/", response_class=Response)
def read_root(templates: Jinja2Templates = Depends(get_mrss_template)):
    """Root endpoint that returns MRSS XML feed with bogus data"""
    # Bogus data for the template
    mrss_data = {
        "feed_url": "https://example.com/feed.xml",
        "items": [
            {
                "title": "Breaking: Local Cat Refuses to Come Inside Despite Owner's Pleas",
                "guid": "cat-story-001",
                "link": "https://san.com/cat-refuses-inside",
                "pubdate": "Wed, 23 Oct 2024 10:30:00 GMT",
                "description": "In a stunning turn of events, Mr. Whiskers has decided that the great outdoors is far superior to his cozy indoor bed.",
                "author": "Jane Reporter",
            },
            {
                "title": "Weather Update: It's Still Weather Outside",
                "guid": "weather-update-002",
                "link": "https://san.com/weather-still-weather",
                "pubdate": "Wed, 23 Oct 2024 09:15:00 GMT",
                "description": "Meteorologists confirm that atmospheric conditions continue to exist in various forms across the region.",
                "author": "Bob Weatherman",
            },
            {
                "title": "Local Person Has Opinion About Things",
                "guid": "opinion-story-003",
                "link": "https://san.com/person-has-opinion",
                "pubdate": "Wed, 23 Oct 2024 08:00:00 GMT",
                "description": "Sources confirm that area resident has formed thoughts regarding current events and is not shy about sharing them.",
                "author": "Mike Journalist",
            },
        ],
    }

    xml_content = templates.get_template("mrss.j2").render(**mrss_data)
    return Response(content=xml_content, media_type="application/xml")
