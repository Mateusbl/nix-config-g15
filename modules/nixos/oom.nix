# earlyoom: kills a runaway process *before* the machine freezes.
#
# The kernel's own OOM killer only acts once memory and swap are completely used up. On a laptop
# with swap that means minutes of a frozen, thrashing desktop first (a JVM, a Node build or a big
# `nh os switch` can do it). earlyoom watches free memory and swap and steps in earlier.
# systemd-oomd is also on, but in this config it does not manage the user session, so the two
# do not overlap.
{
  services.earlyoom = {
    enable = true;

    # Act when less than 10% of RAM is available (default) AND less than 20% of swap is free
    # (default 10%): SIGTERM first, SIGKILL at half of those values. The swap value is higher on
    # purpose: swap here is a 20 GiB disk partition, so waiting for 10% would mean a long thrash,
    # and the same partition holds the hibernation image, so it should never be nearly full.
    freeMemThreshold = 10;
    freeSwapThreshold = 20;

    # Tell me what was killed (shown by mako through systembus-notify), instead of an app just
    # vanishing. This lets any local user send notifications; fine on a single-user laptop.
    enableNotifications = true;

    extraArgs = [
      # Never pick the session itself. These are matched against process names.
      "--avoid"
      "Hyprland|uwsm|ashell|pipewire|wireplumber|oo7-daemon|bootvine|systemd"
      # Prefer Firefox tab processes: losing a tab is better than losing the whole browser.
      "--prefer"
      "Web Content|Isolated Web Co"
    ];
  };
}
