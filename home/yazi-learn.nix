# yazi-learn: hands-on Yazi lessons (`yazi-learn start`, `yazi-learn lesson`, ...).
#
# The lessons below name Yazi *actions* (the `run` strings of Yazi's keymap), never keys.
# At build time yazi-learn/generate.py looks each action up in the installed Yazi's
# default keymap plus this config's additions (home/yazi.nix) and writes the texts with
# the real keys. A lesson that names an action no key runs fails the build, so the
# lessons can never drift from the Yazi you have.
#
# In texts, {{action}} is replaced by the key(s) for that action.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  yazi = config.programs.yazi;

  lessons = [
    {
      title = "Moving around";
      goal = "Move through folders with the keyboard, and know where the built-in help is.";
      steps = [
        { run = "arrow next"; }
        { run = "arrow prev"; }
        { run = "enter"; }
        { run = "leave"; }
        { run = "arrow top"; }
        { run = "arrow bot"; }
        { run = "back"; }
        { run = "forward"; }
        { run = "help"; }
        { run = "quit"; }
      ];
      try = "Walk into nested/level-1/level-2/level-3, open deep.txt's preview, then climb back to the playground root. Open the help, scroll through it, then close it.";
      question = "Which key shows every key Yazi knows, right inside Yazi?";
      answer = "{{help}}";
    }
    {
      title = "Hidden files";
      goal = "Show and hide dotfiles.";
      steps = [ { run = "hidden toggle"; } ];
      try = "Find .hidden-config and the .secret folder in the playground root, then hide them again.";
      question = "Does hiding dotfiles delete or move them?";
      answer = "No. {{hidden toggle}} only changes what is listed.";
    }
    {
      title = "Selecting files";
      goal = "Select one file, a range, everything, or the opposite of the selection.";
      steps = [
        { run = "toggle ; arrow 1"; }
        { run = "visual_mode"; }
        { run = "visual_mode --unset"; }
        { run = "toggle_all --state=on"; }
        { run = "toggle_all"; }
        { run = "escape"; }
      ];
      try = "In many-files, select file-010 to file-020 with visual mode, then invert the selection, then clear it.";
      question = "How do you select every file in a folder at once?";
      answer = "{{toggle_all --state=on}}";
    }
    {
      title = "Copy, cut and paste";
      goal = "Copy (yank) or cut files and paste them somewhere else.";
      steps = [
        { run = "yank"; }
        { run = "yank --cut"; }
        { run = "paste"; }
        { run = "paste --force"; }
        { run = "unyank"; }
      ];
      try = "Copy images/red.png into scratch. Then cut scratch/red.png and paste it into reports. Paste it again over itself with the force variant to see the difference.";
      question = "What happens to the original after you cut and paste?";
      answer = "It is moved: cut ({{yank --cut}}) + paste ({{paste}}) is a move.";
    }
    {
      title = "Create, rename, delete";
      goal = "Make files and folders, rename one or many, and delete safely.";
      steps = [
        { run = "create"; }
        { run = "rename --cursor=before_ext"; }
        { run = "remove"; }
        { run = "remove --permanently"; }
        { run = "plugin trash"; }
      ];
      try = "In scratch: create 'new-folder/' (the trailing / makes a folder), rename trash-me.txt, trash it, then delete gone-for-good.txt permanently. Bulk rename: select all files in rename-me and press the rename key: Yazi opens the names in your editor (Neovim); edit, save and quit.";
      notes = [
        "Trash vs permanent: {{remove}} moves to the trash (you can restore it from the trash bin, {{plugin trash}}); {{remove --permanently}} cannot be undone."
      ];
      question = "How do you rename 50 files at once?";
      answer = "Select them, press {{rename --cursor=before_ext}}, edit the list of names in the editor, save and quit.";
    }
    {
      title = "Filter, find and search";
      goal = "Know the three ways of looking for something.";
      steps = [
        { run = "filter --smart"; }
        { run = "find --smart"; }
        { run = "find_arrow"; }
        { run = "find_arrow --previous"; }
        { run = "search --via=fd"; }
        { run = "search --via=rg"; }
        { run = "escape --search"; }
      ];
      try = "In reports, filter for 'final'. Then use find to jump between files containing 'report'. From the playground root, search names with fd for 'deep', and search contents with ripgrep for 'TODO'.";
      notes = [
        "Filter hides what does not match (current folder). Find only moves the cursor (current folder). Search walks all subfolders and lists the results."
      ];
      question = "Which one looks inside files, not just at names?";
      answer = "Content search via ripgrep: {{search --via=rg}}";
    }
    {
      title = "Jumping with zoxide and fzf";
      goal = "Jump to folders you used before, or fuzzy-find anything below you.";
      steps = [
        { run = "plugin zoxide"; }
        { run = "plugin fzf"; }
        { run = "cd --interactive"; }
        { run = "cd ~"; }
        { run = "follow"; }
      ];
      try = "From the root, fuzzy-find deep.txt with fzf. Go home, then jump back to the playground with zoxide (it learns folders you visit). Hover link-to-deep and follow the symlink.";
      question = "Which jump only knows folders you have visited before?";
      answer = "zoxide: {{plugin zoxide}}";
    }
    {
      title = "Tabs";
      goal = "Work in several folders at once.";
      steps = [
        { run = "tab_create --current"; }
        { run = "tab_switch 0"; }
        { run = "tab_switch 1"; }
        { run = "tab_switch -1 --relative"; }
        { run = "tab_switch 1 --relative"; }
        { run = "close"; }
      ];
      try = "Open a tab, go to images in it, switch back to the first tab, copy a file there and paste it in the images tab. Close the extra tab.";
      question = "What does the close key do on the last tab?";
      answer = "It quits Yazi ({{close}} closes the tab, or quits if it is the last one).";
    }
    {
      title = "Sorting and linemodes";
      goal = "Change the order of files and what is shown next to their names.";
      steps = [
        { run = "sort natural --reverse=no"; }
        { run = "sort alphabetical --reverse=no"; }
        { run = "sort mtime --reverse=no ; linemode mtime"; }
        { run = "sort size --reverse=yes ; linemode size"; }
        { run = "linemode permissions"; }
        { run = "linemode none"; }
      ];
      try = "In sort-me, sort by size (largest first), then by modified time. Show permissions next to the names, then hide the extra column.";
      question = "Which sort puts file-2 before file-10?";
      answer = "Natural sort: {{sort natural --reverse=no}}";
    }
    {
      title = "Open, open with, inspect";
      goal = "Open files with their default app, pick another one, or look at file details.";
      steps = [
        { run = "open"; }
        { run = "open --interactive"; }
        { run = "spot"; }
        { run = "copy path"; }
      ];
      try = "Open notes.md (Neovim), images/plasma.png (imv) and archives/images.zip (extract). Open a PNG 'interactively' and choose 'reveal'. Spot a file to see its details.";
      notes = [
        "This config opens text and code in $EDITOR (Neovim), images in imv, audio/video in mpv, PDFs in zathura, archives with Yazi's extract, and everything else with xdg-open."
      ];
      question = "How do you open a file with something other than its default app?";
      answer = "{{open --interactive}}";
    }
    {
      title = "Shell commands and y";
      goal = "Run commands on the hovered/selected files, and leave Yazi where you want to be.";
      steps = [
        { run = "shell --interactive"; }
        { run = "shell --block --interactive"; }
        { run = "tasks:show"; }
        { run = "quit"; }
        { run = "quit --no-cwd-file"; }
      ];
      try = "Select two files in reports and run: wc -l %s  (blocking, so you see the output). Start Yazi from your shell with `y`, go to images, quit: your shell is now in images. Do it again and quit with the no-cwd variant: the shell stays where it was.";
      notes = [
        "`y` is a shell function (home/yazi.nix): it runs yazi and cds to its last folder on quit. Plain `yazi` never changes your shell's folder."
      ];
      question = "Which quit leaves your shell where it was, even when started with y?";
      answer = "{{quit --no-cwd-file}}";
    }
    {
      title = "Plugins in this config";
      goal = "Use the plugins installed here: git signs, smart-enter, mount, chmod, and reveal in Thunar.";
      steps = [
        { run = "plugin smart-enter"; }
        { run = "plugin mount"; }
        { run = "plugin chmod"; }
        {
          run = "shell --orphan -- thunar \"$(dirname %h)\"";
          note = "Reveal the hovered file in Thunar";
        }
      ];
      try = "Open git-repo: README.md and untracked.txt show git status signs. Use smart-enter on a folder and on a file. Make app.py executable with chmod (mode 755). Reveal it in Thunar. Open the mount manager and quit it.";
      notes = [
        "These keys are additions; none of Yazi's default keys was changed."
      ];
      question = "Where do the git signs come from?";
      answer = "From the git plugin (home/yazi.nix); it needs no key, it runs as a fetcher whenever a folder is listed.";
    }
  ];

  data =
    pkgs.runCommand "yazi-learn-data"
      {
        nativeBuildInputs = [ pkgs.python3 ];
        passAsFile = [
          "lessonsJson"
          "overridesJson"
        ];
        lessonsJson = builtins.toJSON lessons;
        overridesJson = builtins.toJSON (yazi.keymap.mgr.prepend_keymap or [ ]);
      }
      ''
        python3 ${./yazi-learn/generate.py} \
          ${pkgs.yazi-unwrapped.passthru.srcs.code_src}/yazi-config/preset/keymap-default.toml \
          "$overridesJsonPath" "$lessonsJsonPath" "$out" ${pkgs.yazi-unwrapped.version}
      '';

  yazi-learn = pkgs.writeShellApplication {
    name = "yazi-learn";
    runtimeInputs = with pkgs; [
      yazi.finalPackage
      imagemagick
      zip
      gnutar
      gzip
      git
      coreutils
      gawk
    ];
    runtimeEnv.YAZI_LEARN_DATA = "${data}";
    text = builtins.readFile ./yazi-learn/yazi-learn.sh;
  };
in
{
  # The generated lesson data, so docs/yazi-lessons.md can be regenerated:
  #   nix build .#nixosConfigurations.g15.config.home-manager.users.<you>.my.yaziLearn.data
  options.my.yaziLearn.data = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    internal = true;
    default = data;
  };

  config.home.packages = [ yazi-learn ];
}
