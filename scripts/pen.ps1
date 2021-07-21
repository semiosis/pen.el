$pen_config_dir = "$HOME" | Join-Path -ChildPath '.pen'
Write-Host $pen_config_dir
If(!(test-path $pen_config_dir))
{
    New-Item -ItemType Directory -Force -Path $pen_config_dir
}

$openai_api_key_file = "$pen_config_dir" | Join-Path -ChildPath 'openai_api_key'
If(!(test-path $openai_api_key_file))
{
    $openai_api_key = Read-Host -Prompt 'Input OpenAI API key'
    New-Item -ItemType Directory -Force -Path $pen_config_dir
    $openai_api_key | Out-File $openai_api_key_file
}

# $penelloc = "$PSScriptRoot"
$here = $pwd
$prompts_dir = "$here" | Join-Path -ChildPath 'prompts'
Write-Host $prompts_dir
If(!(test-path $prompts_dir))
{
    git clone "https://github.com/semiosis/prompts"
}

docker run `
  -v "${pen_config_dir}:/root/.pen" `
  -v "${prompts_dir}:/root/.emacs.d/host/prompts" `
  -ti --entrypoint= semiosis/pen.el:latest ./run.sh