#!/usr/bin/python3

from aixapi import AIxResource
import os

if __name__ == "__main__":
    # Get your API Key at apps.aixsolutionsgroup.com

    api_key = os.environ.get("AIX_API_KEY")
    aix_resource = AIxResource(api_key)

    model = "GPT-J-6B"

    # GPT-J-6B is the default and will break when supplied
    if model == "GPT-J-6B":
        model = None

    #  token_min_length=min_tokens,

    print(
        str(
            aix_resource.compose(
                "Once upon a time",
                token_min_length = 1,
                token_max_length = 5,
                top_p = 1.0,
                top_k = 10,
                temperature = 0.8,
                stop_sequence = "###",
                custom_model_id = model,
            )
            .get("data", dict())
            .get("text")
        )
    )
