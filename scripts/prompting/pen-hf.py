#!/usr/bin/python3
#!/usr/bin/env python-trace

# https://api-inference.huggingface.co/docs/python/html/detailed_parameters.html#text-generation-task

import json
import os
import requests

API_TOKEN = os.environ.get("HF_API_KEY")
PEN_MODEL = os.environ.get("PEN_MODEL")
PEN_PROMPT = os.environ.get("PEN_PROMPT")
PEN_MODE = os.environ.get("PEN_MODE")
PEN_TRAILING_WHITESPACE = os.environ.get("PEN_TRAILING_WHITESPACE")

API_URL = f"https://api-inference.huggingface.co/models/{PEN_MODEL}"
headers = {"Authorization": f"Bearer {API_TOKEN}"}

# Test
# PEN_PROMPT="* TODO I need more advanced text" PEN_LM_COMMAND="hf-complete.sh" PEN_MODEL="bigscience/T0pp" PEN_APPROXIMATE_PROMPT_LENGTH=18 PEN_ENGINE_MIN_TOKENS=0 PEN_ENGINE_MAX_TOKENS=2049 PEN_MIN_TOKENS=0 PEN_MAX_TOKENS=23 PEN_REPETITION_PENALTY="" PEN_LENGTH_PENALTY="" PEN_MIN_GENERATED_TOKENS=3 PEN_MAX_GENERATED_TOKENS=5 PEN_TEMPERATURE="0.3" PEN_MODE="" PEN_STOP_SEQUENCE="##long complete##" PEN_TOP_P="1" PEN_TOP_K="" PEN_FLAGS= PEN_CACHE= PEN_USER_AGENT="emacs/pen" PEN_TRAILING_WHITESPACE="" PEN_N_COMPLETIONS="10" PEN_ENGINE_MAX_GENERATED_TOKENS=4096 PEN_COLLECT_FROM_POS=32 lm-complete -d | xa find {} -type f | xa cat

# print(API_URL)
# exit()

# import shanepy
# import shanepy as spy
# from shanepy import *

no_parameters = os.environ.get("NO_PARAMETERS") and ("y" == os.environ.get("NO_PARAMETERS"))
remove_prompt_from_gen = os.environ.get("REMOVE_PROMPT_FROM_GEN") and ("y" == os.environ.get("REMOVE_PROMPT_FROM_GEN"))

def query(payload):
    data = json.dumps(payload)

    # myembed(globals(), locals())

    response = requests.request("POST", API_URL, headers=headers, data=data)
    # tv(data)
    return json.loads(response.content.decode("utf-8"))

#  from shanepy import *
#  myembed(globals(), locals())

if PEN_MODE == "summarize":
    if no_parameters:
        ret = query(
            {
                "inputs": PEN_PROMPT,
                # "options": {"wait_for_model": True},
            }
        )
    else:
        ret = query(
            {
                "inputs": PEN_PROMPT,
                "parameters": {
                    "top_k": os.environ.get("PEN_TOP_K") and int(os.environ.get("PEN_TOP_K")),
                    "top_p": os.environ.get("PEN_TOP_P") and float(os.environ.get("PEN_TOP_P")),
                    "temperature": os.environ.get("PEN_TEMPERATURE") and float(os.environ.get("PEN_TEMPERATURE")),
                    "repetition_penalty": os.environ.get("PEN_REPETITION_PENALTY")
                    and float(os.environ.get("PEN_REPETITION_PENALTY")),
                    # "max_new_tokens": os.environ.get("PEN_MAX_TOKENS") and int(os.environ.get("PEN_MAX_TOKENS")),
                    "num_return_sequences": os.environ.get("PEN_N_COMPLETIONS")
                    and int(os.environ.get("PEN_N_COMPLETIONS")),
                    # "return_full_text": False,
                },
                # "options": {"wait_for_model": True},
            }
        )

    print(PEN_PROMPT + ret[0].get("summary_text"))
else:
    if no_parameters:
        ret = query(
            {
                "inputs": PEN_PROMPT,
                # "options": {"wait_for_model": True},
            }
        )
    else:
        ret = query(
            {
                "inputs": PEN_PROMPT,
                "parameters": {
                    "top_k": os.environ.get("PEN_TOP_K")
                    and int(os.environ.get("PEN_TOP_K")),
                    "top_p": os.environ.get("PEN_TOP_P")
                    and float(os.environ.get("PEN_TOP_P")),
                    "temperature": os.environ.get("PEN_TEMPERATURE")
                    and float(os.environ.get("PEN_TEMPERATURE")),
                    "repetition_penalty": os.environ.get("PEN_REPETITION_PENALTY")
                    and float(os.environ.get("PEN_REPETITION_PENALTY")),
                    "max_new_tokens": os.environ.get("PEN_MAX_TOKENS") and int(os.environ.get("PEN_MAX_TOKENS")),
                    "num_return_sequences": os.environ.get("PEN_N_COMPLETIONS")
                    and int(os.environ.get("PEN_N_COMPLETIONS")),
                    "return_full_text": False,
                },
                # "options": {"wait_for_model": True},
            }
        )

    if len(ret) == 1 and type(ret) is list:
        print(PEN_PROMPT + PEN_TRAILING_WHITESPACE + ret[0].get("generated_text"))
    elif len(ret) == 1 and type(ret) is dict and ret.get("error"):
        print(ret.get("error"))
    elif len(ret) > 1:
        for i in range(len(ret)):
            print(f"===== Completion {i} =====")
            print(PEN_PROMPT + PEN_TRAILING_WHITESPACE + ret[i].get("generated_text"))
