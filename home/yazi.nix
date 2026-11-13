# Yazi, the terminal file manager.
#
# Yazi's DEFAULT keymap is kept as it is, so tutorials and `yazi-learn` (home/yazi-learn.nix)
# match. Additions only use keys that are free in the default keymap.
{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;

    # `y` starts yazi and, when you quit with `q`, leaves the shell in yazi's last directory.
    # Set explicitly: home-manager's default name depends on home.stateVersion.
    enableZshIntegration = true;
    shellWrapperName = "y";

    # nixpkgs' yazi wrapper already puts the preview tools on yazi's PATH: ffmpeg (video
    # thumbnails), poppler (PDF), imagemagick (images, fonts), 7zip (archives), jq (JSON),
    # fd/ripgrep/fzf/zoxide (search and jumps), resvg (SVG) and chafa. Only git is added,
    # for the git plugin. Images are shown with the kitty graphics protocol, which Ghostty
    # speaks natively, so no ueberzugpp is needed.
    extraPackages = [ pkgs.git ];

    # Plugins from nixpkgs' yaziPlugins (never `ya pkg`, see CLAUDE.md).
    plugins = {
      # Git status signs next to file names. Needs the fetchers below.
      git = {
        package = pkgs.yaziPlugins.git;
        setup = true;
      };
      smart-enter = pkgs.yaziPlugins.smart-enter; # enter a directory or open a file
      mount = pkgs.yaziPlugins.mount; # mount/unmount/eject partitions
      chmod = pkgs.yaziPlugins.chmod; # chmod selected files
    };

    settings = {
      plugin.prepend_fetchers = [
        {
          url = "*";
          run = "git";
          group = "git";
        }
        {
          url = "*/";
          run = "git";
          group = "git";
        }
      ];

      # How files open with Enter / `o`. %s = selected files, %s1 = the first one.
      # `orphan` lets a GUI app keep running after yazi quits; `block` hands the terminal
      # to a terminal program (the editor) until it exits.
      opener = {
        edit = [
          {
            run = "\${EDITOR:-nvim} %s";
            desc = "$EDITOR";
            block = true;
          }
        ];
        image = [
          {
            run = "imv %s";
            desc = "imv";
            orphan = true;
          }
        ];
        media = [
          {
            run = "mpv %s";
            desc = "mpv";
            orphan = true;
          }
        ];
        pdf = [
          {
            run = "zathura %s1";
            desc = "zathura";
            orphan = true;
          }
        ];
      };

      # Checked before yazi's built-in rules. Anything not matched here keeps the default:
      # text/code -> edit, archives -> extract (7zip), everything else -> xdg-open.
      open.prepend_rules = [
        {
          mime = "text/*";
          use = [
            "edit"
            "reveal"
          ];
        }
        {
          mime = "image/*";
          use = [
            "image"
            "open"
            "reveal"
          ];
        }
        {
          mime = "{audio,video}/*";
          use = [
            "media"
            "open"
            "reveal"
          ];
        }
        {
          mime = "application/pdf";
          use = [
            "pdf"
            "open"
            "reveal"
          ];
        }
      ];
    };

    # Extra keys. Each one was checked to be unused in yazi's default keymap
    # (yazi-config/preset/keymap-default.toml), so no default changes.
    keymap.mgr.prepend_keymap = [
      {
        on = [
          "g"
          "r"
        ];
        run = "shell --orphan -- thunar \"$(dirname %h)\"";
        desc = "Reveal in Thunar";
      }
      {
        # smart-enter's README binds `l`; that would change a default key, so it gets
        # its own key instead (see docs/questions.md).
        on = "<C-l>";
        run = "plugin smart-enter";
        desc = "Enter the child directory, or open the file";
      }
      {
        on = "M";
        run = "plugin mount";
        desc = "Mount manager";
      }
      {
        on = [
          "c"
          "m"
        ];
        run = "plugin chmod";
        desc = "Chmod on selected files";
      }
    ];
  };

  # Viewers yazi (and the desktop) open files with.
  home.packages = with pkgs; [
    imv # images
    mpv # audio and video
    zathura # PDF (zathura in nixpkgs includes the mupdf PDF plugin)
  ];

  # Default apps for the desktop (Thunar, xdg-open). Directories -> Thunar and
  # text/plain -> Mousepad are set in home/session.nix and stay as they are.
  xdg.mimeApps.defaultApplications =
    let
      imv = "imv.desktop";
      mpv = "mpv.desktop";
    in
    {
      "image/png" = imv;
      "image/jpeg" = imv;
      "image/gif" = imv;
      "image/webp" = imv;
      "image/bmp" = imv;
      "image/tiff" = imv;
      "image/svg+xml" = imv;
      "video/mp4" = mpv;
      "video/x-matroska" = mpv;
      "video/webm" = mpv;
      "video/quicktime" = mpv;
      "video/x-msvideo" = mpv;
      "audio/mpeg" = mpv;
      "audio/flac" = mpv;
      "audio/ogg" = mpv;
      "audio/x-wav" = mpv;
      "audio/mp4" = mpv;
      "application/pdf" = "org.pwmt.zathura-pdf-mupdf.desktop";
    };
}
