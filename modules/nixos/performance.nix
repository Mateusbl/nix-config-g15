# Speed and responsiveness. The base is already current: nixos-unstable, the newest kernel
# (boot.nix), dbus-broker, a systemd initrd and zstd-compressed zram. This file adds the tuning
# on top. Each block is independent; delete one to go back to the kernel's defaults.
{
  # A sched_ext CPU scheduler (kernel 6.12+): a scheduler loaded as a BPF program instead of
  # the built-in one. scx_bpfland favours interactive tasks, so the desktop, audio and the
  # editor stay smooth while a build uses every core. If such a scheduler ever misbehaves the
  # kernel unloads it and falls back to the built-in scheduler by itself.
  # `scxctl get` shows what is running; `scxctl switch --sched lavd` tries another one.
  services.scx-loader = {
    enable = true;
    config.default_sched = "scx_bpfland";
  };

  boot.kernel.sysctl = {
    # Memory: zram (power-sleep.nix) is swap that lives compressed in RAM, so swapping to it is
    # cheap. These are the values recommended for zram (used by Fedora and Pop!_OS): swap idle
    # pages early instead of dropping file cache, read one page at a time (zram has no seek
    # cost), and wake the reclaimer sooner so allocations rarely stall.
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;

    # Network: BBR congestion control with the fq queueing discipline. Better throughput and
    # lower latency than the default (cubic) on lossy links such as Wi-Fi.
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
  boot.kernelModules = [ "tcp_bbr" ];
}
