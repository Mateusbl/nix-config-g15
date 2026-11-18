{
  description = "Dell G15 5511 NixOS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim configuration framework used by home/editor/neovim.
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative partitioning (hosts/<host>/disko.nix)
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Live systemd job tree on the boot console (modules/nixos/bootvine.nix). Built on this
    # machine from source. The flake's own Cachix is never used: Nix only honours the `nixConfig`
    # of the top-level flake, and `accept-flake-config = false` in modules/nixos/nix.nix blocks it
    # anyway. Delete this input once nixpkgs ships services.bootvine.
    bootvine = {
      url = "git+https://codeberg.org/wvhulle/bootvine";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secure Boot for systemd-boot (modules/nixos/boot.nix). Not in nixpkgs. Pinned to a release
    # and compiled on this machine; its Cachix is never used (same reason as bootvine above).
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
      # Only used for lanzaboote's own development (git hooks); dropping it keeps the lock smaller.
      inputs.pre-commit.follows = "";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      home-manager,
      stylix,
      nixvim,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      username = "mateus";

      # One entry per machine: attribute name = directory under hosts/.
      # The attribute name (g15) is what `--flake .#g15` and `nh os ... -H g15` select; `hostname`
      # is only the machine's network name. nh picks the output by hostname unless -H is given.
      mkHost =
        { dir, hostname }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              self
              username
              hostname
              ;
          };
          modules = [
            ./hosts/${dir}

            # Generic hardware profiles (there is no dell-g15-5511 module in nixos-hardware)
            nixos-hardware.nixosModules.common-cpu-intel
            nixos-hardware.nixosModules.common-gpu-nvidia
            nixos-hardware.nixosModules.common-pc-laptop
            nixos-hardware.nixosModules.common-pc-laptop-ssd

            stylix.nixosModules.stylix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit inputs username; };
                sharedModules = [ nixvim.homeModules.nixvim ];
                users.${username} = import ./home;
              };
            }
          ];
        };
    in
    {
      # Enables `nix fmt` across the repository
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;

      nixosConfigurations = {
        # Keep the hostname "nixos" for now so the running system still matches.
        # To rename the machine, change it here, then the first switch needs:
        #   nh os switch -H g15
        g15 = mkHost {
          dir = "g15";
          hostname = "nixos";
        };
      };
    };
}
