let
  ci =
    { pkgs, ... }:
    let
      npmTools = pkgs.callPackage ./pkgs/npm-tools.nix { };
    in
    {
      languages.elm.enable = true;

      env.NODE_PATH = "${npmTools}/lib/node_modules";

      packages = [
        npmTools
        pkgs.nodejs_22
      ];

      enterShell = ''
        ln -sfn "${npmTools}/lib/node_modules" node_modules
        ln -sfn "${npmTools}/lib/node_modules" elm-app/node_modules
      '';
    };

  shell =
    { pkgs, ... }:
    let
      npmTools = pkgs.callPackage ./pkgs/npm-tools.nix { };
    in
    {
      languages.elm.enable = true;

      dotenv.enable = true;

      env.NODE_PATH = "${npmTools}/lib/node_modules";

      packages = with pkgs; [
        entr
        git
        nodejs_22
        treefmt
        elmPackages.elm-review
        elmPackages.elm-json
        npmTools
      ];

      enterShell = ''
        ln -sfn "${npmTools}/lib/node_modules" node_modules
        ln -sfn "${npmTools}/lib/node_modules" elm-app/node_modules

        echo ""
        echo "── membership-card dev environment ──────────────────"
        echo "  Elm:    $(elm --version)"
        echo "  Node:   $(node --version)"
        echo "  Vite:   $(vite --version)"
        echo ""
        echo "  make elm-dev    — start Vite dev server"
        echo "  make watch      — alias for elm-dev"
        echo "  make dist-ci    — production build → build/"
        echo ""
      '';
    };
in
{
  profiles.shell.module = {
    imports = [ shell ];
  };

  profiles.ci.module = {
    imports = [ ci ];
  };
}
