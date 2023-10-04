{ inputs, config, pkgs, lib, ... }:
with lib;
let
  initFile = ./init.el;
  initFileStr = concatMapStringsSep "\n" builtins.readFile
    config.programs.emacs.custom.extraInit;
  initMagit = pkgs.writeText "magit-exe.el"
    ''(setq magit-git-executable "${pkgs.git}/bin/git")'';
in {
  options.programs.emacs.custom = {
    extraInit = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "the extra Init files to merge into the final init.el file";
    };
    package = mkOption {
      type = types.package;
      default = pkgs.emacs29;
      defaultText = literalExpression "pkgs.stable.emacs";
      description = lib.mdDoc ''
        emacs derivation to use with emacsWithPackagesFromUsePackage
      '';
    };
    override = mkOption {
      type = types.functionTo (types.functionTo (types.attrsOf types.package));
      default = (self: super: { });
      description =
        "Overrides/overlay for packages in emacsWithPackagesFromUsePackage";
    };
  };

  config = {
    home.packages = [
      pkgs.nodejs
      pkgs.nixfmt
      pkgs.scalafmt

    ];

    programs.emacs = {
      enable = true;
      package = pkgs.emacsWithPackagesFromUsePackage {
        package = config.programs.emacs.custom.package;
        override = self: epkgs:
          (config.programs.emacs.custom.override self epkgs) // {
            copilot = let
              copilot-lisp = epkgs.trivialBuild {
                pname = "copilot-lisp";
                src = inputs.copilot-el;
                packageRequires = [ epkgs.dash epkgs.editorconfig epkgs.s ];
              };
              copilot-dist = pkgs.stdenv.mkDerivation {
                name = "copilot-dist";
                src = inputs.copilot-el;
                installPhase =
                  "  LISPDIR=$out/share/emacs/site-lisp\n  mkdir -p $LISPDIR\n  cp -R dist $LISPDIR\n";
              };
            in pkgs.symlinkJoin {
              name = "emacs-copilot";
              paths = [ copilot-lisp copilot-dist ];
            };
          };

        config = initFileStr;
        defaultInitFile = false;
        alwaysEnsure = true;
      };
      custom.extraInit = lib.mkBefore [ initFile initMagit ];
      extraPackages = epkgs: [ epkgs.use-package ];
    };

    xdg.configFile = {
      "emacs/init.el".text = initFileStr;
      "emacs/early-init.el".source = ./early-init.el;
      "emacs/load-path.el".source = pkgs.writeText "load-path.el" ''
                (let ((default-directory (file-name-as-directory
        				"${config.programs.emacs.package.deps}/share/emacs/site-lisp/"))
        	    (normal-top-level-add-subdirs-inode-list nil))
              (normal-top-level-add-subdirs-to-load-path))
      '';
    };
  };
}
