# Special Cases: NixOS

This document covers compliance for a special case distribution: NixOS.
The contents of this document are intentionally high level to prevent drift.

## Onboarding Guide

1. Follow the guide in the [README](../README.md) until the step involving editing the installation variables
1. Perform the compliance token step and have your compliance token handy
1. Run the following command: `sudo mkdir -p /etc/si-device-compliance`
1. Replace the `<YOUR-TOKEN-HERE>` argument with your token in the _next_ step
1. Run the following command: `echo <YOUR-TOKEN-HERE> | sudo tee /etc/si-device-compliance/token.txt`
1. Edit the installation variables file and follow all NixOS-relevant tips in the file (e.g. using the token file path)

Now that we have perform the initial setup steps, we can extend our NixOS configuration.
Add the following to your NixOS configuration (e.g. `configuration.nix`):

```nix
imports = [
  (import (builtins.fetchurl {
    url = "https://raw.githubusercontent.com/systeminit/si-device-compliance/refs/heads/main/special-cases/compliance/si-nixos-configuration.nix";
    sha256 = lib.fakeSha256;
  }))
];
```

After that, reload your NixOS configuration, add the correct `sha256` (you'll be told what it is), and reload again.
You may need to reboot your system after this dance.

**You can now return to the guide in the [README](../README.md)!**
