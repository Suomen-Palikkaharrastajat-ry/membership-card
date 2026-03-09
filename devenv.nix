let
  shell = { pkgs, ... }: {
    packages = [
      pkgs.nodejs
    ];
    dotenv.enable = true;
  };
in {
  profiles.shell.module = {
    imports = [ shell ];
  };
}
