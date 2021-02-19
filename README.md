# `prompt-engineer-mode` (`PEn`)

Prompt-Engineer Mode is a global minor mode for emacs that facilitates the
creation, development, discovery and usage of prompts to a language model.

-   Create elisp functions based on GPT-3 prompts
-   Chain GPT-3 queries together using keyboard macros and functions
-   Interactively query, generate and transfrom both prose and code
-   Use GPT-3 as a search engine within emacs
    -   Search the internet
    -   Search documents
        -   <https://beta.openai.com/docs/introduction/semantic-search>
        -   <https://gpttools.com/semanticsearch>


[![asciicast](https://asciinema.org/a/t7ATnFpnfzBp0yicIlGCt6eXi.png)](https://asciinema.org/a/t7ATnFpnfzBp0yicIlGCt6eXi)

## Works with

-   OpenAI API (GPT-3)
    -   <https://beta.openai.com/>


### Planned

-   `openai-server` (GPT-2)
    -   <https://github.com/shawwn/openai-server>
    -   Requires tensorflow 1
-   DeepAI API
    -   <https://deepai.org/>
-   OpenAI API (GPT-4)
    -   <https://beta.openai.com/>


## Requirements


### `openai` `pip` library and command

    1  pip3 install openai


### `openai` API key


## Usage


### Enable `prompt-engineerer-mode` globally (on all buffers)

    1  (prompt-engineer-mode 1)
    2  
    3  ;; Alternatively
    4  (pen-mode 1)


## Current progress

-   Implementation <code>[1/1]</code>
    -   [X] emacs-lisp functions are generated from YAML `.prompt` files
-   Design <code>[1/2]</code>
    -   [X] Default behaviour of generated functions
        -   [X] First argument may be selection
        -   [ ]If selection then text is replaced by default
    -   [ ] Generate functions of composed prompts
    -   Development workflow
    -   Search workflow
-   Portability <code>[0/1]</code>
    -   [-] Use built-in elisp functions


## Appendix

[Prompt Engineering](https://www.google.com/search?q=prompt+engineering+gpt)


# Using `pen`

<https://asciinema.org/a/t7ATnFpnfzBp0yicIlGCt6eXi>


## <span class="underline">How to crack an egg</span> &#x2013; The obfuscated version

     1  In order to understand the process of how to
     2  crack an egg, one must first understand the
     3  egg itself.
     4  
     5  Eggs are oval objects which are comprised of
     6  the remnants of expired cellular tissue, as
     7  the human body is comprised.
     8  
     9  The origin of the egg can be traced back to
    10  the reproductive organ of a female bird.
    11  
    12  Once the egg is laid, it is then incubated, a
    13  process which can take several weeks.
    14  
    15  The term “founders” refers in this case to a
    16  period where the human


<a id="orgca7d14c"></a>

### Now let's summarize that paragraph for a 2nd grader.

     1  An egg is a small round object that comes from
     2  a hen.
     3  
     4  It is made of the stuff that comes out of the
     5  hen's butt.
     6  
     7  The egg is like the human body, because the
     8  body is also made of the stuff that comes out
     9  of the butt.
    10  
    11  The egg is incubated for a few weeks.
    12  
    13  This means that it is kept warm so it can
    14  grow.
    15  
    16  The egg is like a human baby, because a human
    17  baby is also kept warm so it can grow.
    18  
    19  The hen is


## Creating some analogies


### Strawberries are like the ocean because:

    1  both are systems whose properties are best 
    2  appreciated from a distance.


### Strawberries are like the ocean because:

Ok&#x2026; We can adjust the analogy `.prompt` file.

I have adjusted it with a temperature of 0.7
so it can get really creative, and also
adjusted the presence penalty to make it a bit
more verbose.

    1  both need to be protected from pollution.

I actually really like this one.


## This is the generated analogy function

     1  pen-make-analogy is an interactive function defined in my-openai.el.
     2  
     3  Signature
     4  (pen-make-analogy FORMER LATTER)
     5  
     6  Key Bindings
     7  This command is not in any keymaps.
     8  
     9  References
    10  pen-make-analogy is unused in my-openai.el.
    11  
    12  Find all references Find callees
    13  
    14  Debugging
    15  Enable tracing
    16  Disassemble Forget
    17  
    18  Source Code
    19  ;; Defined in ~/source/git/config/emacs/config/my-openai.el
    20  ;; Could not find source code, showing raw function object.
    21  (lambda
    22    (former latter)
    23    (interactive
    24     (list
    25      (read-string-hist "analogy participant: ")
    26      (read-string-hist "analogy participant: ")))
    27    (let*
    28        ((prompt-fp
    29          (umn "$MYGIT/mullikine/prompt-engineer-mode/prompts/analogy.prompt")))
    30      (etv
    31       (sn
    32        (concat "openai-complete "
    33                (q prompt-fp)
    34                " "
    35                (q former)
    36                " "
    37                (q latter)
    38                " | chomp")))))
    39  
    40  Symbol Properties
    41  event-symbol-element-mask
    42    (pen-make-analogy 0)
    43  event-symbol-elements
    44    (pen-make-analogy)
    45  modifier-cache
    46    ((0 . pen-make-analogy))

