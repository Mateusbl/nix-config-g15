# Networking, locale, and the small set of system-wide packages.
{ pkgs, ... }:

{
  networking = {
    nftables.enable = true;
    networkmanager = {
      enable = true;
      # iwd (Intel's Wi-Fi daemon) instead of wpa_supplicant: it connects and roams faster and
      # is smaller. NetworkManager still owns the networks you save, so the panel, nmtui and
      # oo7-stored passwords work as before. To go back, delete this line.
      wifi.backend = "iwd";
    };
    firewall.enable = true;
  };

  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };
  # US keyboard: the default console keymap is already correct (ly password entry)

  # System packages (everything else lives in home/)
  environment.systemPackages = with pkgs; [
    nil
    nixfmt
    git
    curl
    wget
    pciutils
    usbutils
  ];

  # Keep at most 1 GiB of system logs (the default is up to 4 GiB of the root filesystem).
  services.journald.settings.Journal.SystemMaxUse = "1G";
}
