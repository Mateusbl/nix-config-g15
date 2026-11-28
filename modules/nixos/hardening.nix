# Kernel and network settings that close small information leaks and old network tricks.
# Each one is cheap and changes nothing you would notice on a desktop; delete a line to go back
# to the kernel's default.
{
  boot.kernel.sysctl = {
    # Kernel addresses: hidden from everyone (they help exploits find their target), and the
    # kernel log (`dmesg`) readable only by root, since it shows them too. Use `sudo dmesg`.
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;

    # Ignore ICMP redirects (a router on the network telling this laptop to send its traffic
    # somewhere else) and never send them: a laptop is not a router. Coffee-shop Wi-Fi is the
    # kind of network where someone would try this.
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;

    # Ignore packets that ask to choose their own route through the network (source routing).
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
  };
}
