#!/usr/bin/python3

from aixapi import AIxResource
import os

def hard_bound(x, lower_lim, upper_lim):
    if (x is not None) and (upper_lim is not None) and x > upper_lim:
        return upper_lim

    if (x is not None) and (lower_lim is not None) and x < lower_lim:
        return lower_lim

    return x

if __name__ == "__main__":
    # Get your API Key at apps.aixsolutionsgroup.com

    min_tokens = os.environ.get("PEN_MIN_TOKENS") and int(os.environ.get("PEN_MIN_TOKENS"))
    max_tokens = os.environ.get("PEN_MAX_TOKENS") and int(os.environ.get("PEN_MAX_TOKENS"))
    max_generated_tokens = os.environ.get("PEN_MAX_GENERATED_TOKENS") and int(os.environ.get("PEN_MAX_GENERATED_TOKENS"))
    engine_min_tokens = os.environ.get("PEN_ENGINE_MIN_TOKENS") and int(os.environ.get("PEN_ENGINE_MIN_TOKENS"))
    engine_max_tokens = os.environ.get("PEN_ENGINE_MAX_TOKENS") and int(os.environ.get("PEN_ENGINE_MAX_TOKENS"))
    engine_max_generated_tokens = os.environ.get("PEN_ENGINE_MAX_GENERATED_TOKENS") and int(os.environ.get("PEN_ENGINE_MAX_GENERATED_TOKENS"))

    min_tokens = hard_bound(min_tokens, engine_min_tokens, engine_max_tokens)
    max_tokens = hard_bound(max_tokens, engine_min_tokens, engine_max_tokens)

    if engine_max_generated_tokens:
        max_generated_tokens = hard_bound(max_generated_tokens, 0, engine_max_generated_tokens)

    if not max_generated_tokens:
        max_generated_tokens = max_tokens

    # print(min_tokens)
    # print(max_tokens)
    # print(max_generated_tokens)
    # exit()

    #  vim +/"top_k: int" "$MYGIT/AIx-Solutions/aix-gpt-api/aixapi/resource.py"

    final_top_p = os.environ.get("PEN_TOP_P") and float(os.environ.get("PEN_TOP_P"))
    final_top_k = os.environ.get("PEN_TOP_K") and int(os.environ.get("PEN_TOP_K"))

    final_temperature = os.environ.get("PEN_TEMPERATURE") and float(os.environ.get("PEN_TEMPERATURE"))

    final_stop_sequence = os.environ.get("PEN_STOP_SEQUENCE")

    api_key = os.environ.get("AIX_API_KEY")
    aix_resource = AIxResource(api_key)

    model = os.environ.get("PEN_MODEL")

    # GPT-J-6B is the default and will break when supplied
    if model == "GPT-J-6B":
        model = None

    #  token_min_length=min_tokens,

    print(
        str(
            aix_resource.compose(
                os.environ.get("PEN_PROMPT"),
                token_min_length = 1,
                token_max_length = max_generated_tokens,
                top_p = final_top_p,
                top_k = final_top_k,
                temperature = final_temperature,
                stop_sequence = final_stop_sequence,
                custom_model_id = model,
            )
            .get("data", dict())
            .get("text")
        )
    )
