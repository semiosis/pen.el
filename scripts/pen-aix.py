#!/usr/bin/python3

from aixapi import AIxResource
import os

# Get your API Key at apps.aixsolutionsgroup.com

# model=os.environ.get("PEN_MODEL"),

if __name__ == "__main__":
    api_key = os.environ.get("AIX_API_KEY")
    aix_resource = AIxResource(api_key)
    print(
        str(
            aix_resource.compose(
                os.environ.get("PEN_PROMPT"),
                response_length=int(os.environ.get("PEN_MAX_TOKENS")),
                top_p=float(os.environ.get("PEN_TOP_P")),
                temperature=float(os.environ.get("PEN_TEMPERATURE")),
                stop_sequence=os.environ.get("PEN_STOP_SEQUENCE"),
            )
            .get("data", dict())
            .get("text")
        )
    )
