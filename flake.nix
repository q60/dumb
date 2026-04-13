{
  description = "alternative frontend for genius.com";

  outputs = {self}: {
    nixosModules.default = {
      config,
      lib,
      pkgs,
      ...
    }: let
      cfg = config.services.dumb;
      rev = "188d5f7e41e5fdafab88f30e1b2c3e558399b53d";

      package = pkgs.buildGoModule {
        name = "dumb";

        src = pkgs.fetchFromGitHub {
          owner = "rramiachraf";
          repo = "dumb";
          rev = rev;
          sha256 = "sha256-g+MBVqdPtG8ugBfYxjIrJgGcDnikzHgHnjcCYC5vx2Y=";
        };

        vendorHash = "sha256-A9QjEYdjwcB690PVpm0NS5vjxpl12gKtrwIMZbS7ym0=";

        checkPhase = [];

        ldflags = [
          "-X 'github.com/rramiachraf/dumb/data.Version=${rev}' -s -w"
        ];

        preBuild = ''
          go tool templ generate
          cat ./style/*.css | go tool esbuild --loader=css --minify > ./static/style.css
        '';
      };
    in {
      options.services.dumb = {
        enable = lib.mkEnableOption "dumb service";

        port = lib.mkOption {
          type = lib.types.port;
          default = 5555;
        };
      };

      config = lib.mkIf cfg.enable {
        nixpkgs.overlays = [(final: prev: {dumb = package;})];

        systemd.services.dumb = {
          wantedBy = ["multi-user.target"];

          after = ["network.target"];

          environment = {
            PORT = toString cfg.port;
          };

          serviceConfig.ExecStart = "${pkgs.dumb}/bin/dumb";
        };
      };
    };
  };
}
