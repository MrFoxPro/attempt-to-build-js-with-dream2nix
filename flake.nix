{
  description = "A very basic flake";
  inputs = {
    # <frameworks>
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # <devtools>
    flake-root.url = "github:srid/flake-root";
    proc-flake.url = "github:srid/proc-flake";
    # <app builders>
    dream2nix.url = "github:nix-community/dream2nix";
  };

  outputs = inputs:
    with builtins; let
      lib = inputs.nixpkgs.lib;
    in
      with lib;
        inputs.flake-parts.lib.mkFlake {inherit inputs;}
        {
          imports = with inputs; [
            proc-flake.flakeModule
            flake-root.flakeModule
            dream2nix.flakeModuleBeta
          ];
          systems = ["x86_64-linux"];
          perSystem = {
            config,
            self',
            system,
            inputs',
            ...
          }: let
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = [
                (final: prev: {
                  nodejs = prev.nodejs_20;
                })
              ];
            };
          in {
            _module.args = {inherit lib pkgs;};
            proc.groups.dev.processes = {
              web.command = "cd ./web && vite";
            };
            dream2nix.inputs.app = {
              source = ./app;
              projects.app = {name, ...}: {
                inherit name;
                relPath = "";
                subsystem = "nodejs";
                translator = "package-json";
                builder = "strict-builder";
              };
            };

            dream2nix.inputs.app2 = {
              source = ./.;
              projects.app2 = {name, ...}: {
                inherit name;
                relPath = "./app";
                subsystem = "nodejs";
                translator = "package-json";
                builder = "strict-builder";
              };
            };

            packages = config.dream2nix.outputs.app.packages // config.dream2nix.outputs.app2.packages;

            devShells.default = pkgs.mkShell {
              shellHook = ''
                echo Hello from shell
                echo Try running nix run .#app.resolve; nix build .#app
                echo Try running nix run .#app2.resolve; nix build .#app2
              '';
              packages = [
                # self'.packages.web # doesn't work?
              ];
            };
          };
        };
}
