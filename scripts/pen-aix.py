#!/usr/bin/python3

from aixapi import AIxResource
import os

# Get your API Key at apps.aixsolutionsgroup.com

if __name__ == "__main__":
    api_key = os.environ.get("AIX_API_KEY")
    aix_resource = AIxResource(api_key)
    print(
        str(
            aix_resource.compose(
                os.environ.get("PEN_PROMPT"),
                token_min_length=int(os.environ.get("PEN_MIN_TOKENS")),
                token_max_length=int(os.environ.get("PEN_MAX_TOKENS")),
                top_p=float(os.environ.get("PEN_TOP_P")),
                top_k=float(os.environ.get("PEN_TOP_K")),
                temperature=float(os.environ.get("PEN_TEMPERATURE")),
                stop_sequence=os.environ.get("PEN_STOP_SEQUENCE"),
                custom_model_id=os.environ.get("PEN_MODEL"),
            )
            .get("data", dict())
            .get("text")
        )
    )
