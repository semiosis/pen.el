$pen_config_dir = "$HOME\.pen"
If(!(test-path $pen_config_dir))
{
    New-Item -ItemType Directory -Force -Path $pen_config_dir
}

$openai_api_key_file = "$pen_config_dir\openai_api_key"
If(!(test-path $openai_api_key_file))
{
    $openai_api_key = Read-Host -Prompt 'Input OpenAI API key'
    New-Item -ItemType Directory -Force -Path $pen_config_dir
    $openai_api_key | Out-File $openai_api_key_file
}

$here = $PSScriptRoot
$pen_config_dir = "$HOME\.pen"
If(!(test-path $pen_config_dir))
{
    New-Item -ItemType Directory -Force -Path $pen_config_dir
}

docker.exe run `
  -v "$HOME/.pen:/root/.pen" `
  --directory "$project_root\lisp" `
  --directory "$project_root\langs" `
  --eval "(progn (require 'tree-sitter-langs) (tree-sitter-langs-ensure '$lang))"
