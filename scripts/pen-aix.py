#!/usr/bin/python3

from aixapi import AIxResource
import os

def hard_bound(x, lower_lim, upper_lim):
    if x and \
       upper_lim and \
       x > upper_lim:
        x = upper_lim
    elif x and \
       lower_lim and \
       x < lower_lim:
        x = lower_lim
    else:
        x

# Get your API Key at apps.aixsolutionsgroup.com

max_tokens = os.environ.get("PEN_MAX_TOKENS") and int(os.environ.get("PEN_MAX_TOKENS"))
min_tokens = os.environ.get("PEN_MIN_TOKENS") and int(os.environ.get("PEN_MIN_TOKENS"))
engine_max_tokens = os.environ.get("PEN_ENGINE_MAX_TOKENS") and int(os.environ.get("PEN_ENGINE_MAX_TOKENS"))
engine_min_tokens = os.environ.get("PEN_ENGINE_MIN_TOKENS") and int(os.environ.get("PEN_ENGINE_MIN_TOKENS"))

max_tokens = hard_bound(max_tokens, engine_min_tokens, engine_max_tokens)
min_tokens = hard_bound(min_tokens, engine_min_tokens, engine_max_tokens)

print(engine_min_tokens)
#  print(str(min_tokens))
exit(0)

if __name__ == "__main__":
    api_key = os.environ.get("AIX_API_KEY")
    aix_resource = AIxResource(api_key)
    print(
        str(
            aix_resource.compose(
                os.environ.get("PEN_PROMPT"),
                token_min_length = min_tokens,
                token_max_length = max_tokens,
                #  top_p = os.environ.get("PEN_TOP_P") and float(os.environ.get("PEN_TOP_P")),
                #  top_k = os.environ.get("PEN_TOP_K") and float(os.environ.get("PEN_TOP_K")),
                temperature = os.environ.get("PEN_TEMPERATURE") and float(os.environ.get("PEN_TEMPERATURE")),
                stop_sequence = os.environ.get("PEN_STOP_SEQUENCE"),
                #  model = os.environ.get("PEN_MODEL"),
            )
            .get("data", dict())
            .get("text")
        )
    )
