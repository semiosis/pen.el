# run docker with volume

# resolvepath of directory

docker run -v /home/shane/.pen:/root/.pen -v /home/ shane/var/smulliga/source/git/semiosis/prompts :/root/.emacs.d/host/prompts -v pen.el:/root/.emacs.d/host/pen.el -ti --entrypoint= semiosis/pen.el:latest ./run.sh 'docker' 'run' '-v' '/home/shane/.pen:/root/.pen' '-v' '/home/shan e/var/smulliga/source/git/semiosis/prompts:/ro ot/.emacs.d/host/prompts' '-v' 'pen.el:/root/.emacs.d/host/pen.el' '-ti' '-- entrypoint=' 'semiosis/pen.el:latest' './run.sh'