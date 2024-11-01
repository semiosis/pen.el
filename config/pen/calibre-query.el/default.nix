with import <nixpkgs> {};
stdenv.mkDerivation rec {
    name = "dev-env";
    env = buildEnv {
        name = name;
        paths = buildInputs;
    };
    buildInputs = [
        glibcLocales
        gnome3.gtk
        emacs
        sqlite
        git
    ];
    shellHook = ''
      export GTK_THEME=Adwaita
      export HOME=$PWD/.nix

      eval_forms="(require 'package)"
      eval_forms="$eval_forms (package-initialize)"
      eval_forms="$eval_forms (add-to-list 'package-archives '(\\\"melpa\\\" . \\\"https://melpa.org/packages/\\\") t)"
      alias emacs="emacs --eval=\"(progn $eval_forms)\""

      if [ ! -e $HOME ]; then
        echo "creating .nix directory"
        mkdir -p $HOME

        # dependencies
        emacs -batch --eval="(progn (package-initialize) (package-refresh-contents) (package-install 'sql) (package-install 'ivy) (package-install 'seq))"
        # for best practices
        emacs -batch --eval="(progn (package-initialize) (package-refresh-contents) (package-install 'package-lint))"

        mkdir -p "$HOME/Calibre Library"
        touch "$HOME/Calibre Library/metadata.db"
      fi
    '';
}
