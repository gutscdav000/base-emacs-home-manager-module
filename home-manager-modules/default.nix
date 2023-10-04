rec {
  base-emacs = ./emacs;
  default = {
    imports = [ base-emacs ];
  };
}
