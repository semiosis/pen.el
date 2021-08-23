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
                token_min_length = os.environ.get("PEN_MIN_TOKENS") and float(os.environ.get("PEN_MIN_TOKENS")),
                token_max_length = os.environ.get("PEN_MAX_TOKENS") and float(os.environ.get("PEN_MAX_TOKENS")),
                top_p = os.environ.get("PEN_TOP_P") and float(os.environ.get("PEN_TOP_P")),
                top_k = os.environ.get("PEN_TOP_K") and float(os.environ.get("PEN_TOP_K")),
                temperature = os.environ.get("PEN_TEMPERATURE") and float(os.environ.get("PEN_TEMPERATURE")),
                stop_sequence = os.environ.get("PEN_STOP_SEQUENCE"),
                model = os.environ.get("PEN_MODEL"),
            )
            .get("data", dict())
            .get("text")
        )
    )
