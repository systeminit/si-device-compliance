{
  config,
  lib,
  pkgs,
  ...
}: {
  # ========== INSTRUCTIONS ==========
  # 1) follow the README instructions until you edit the "installation.vars" file
  # 2) prepare your compliance token for the next step (i.e. have it handy!)
  # 3) run the following command: "sudo mkdir -p /etc/si-device-compliance"
  # 4) run the following command (and replace the relevant token piece): "echo <YOUR-TOKEN-HERE> | sudo tee /etc/si-device-compliance/token.txt"
  # 5) follow NixOS-relevant instructions in the "installation.vars" file
  # 6) in that file, set the "SUBMISSION_TOKEN" to "/etc/si-device-compliance/token.txt"
  # 7) import THIS file into your NixOS configuration using "imports = [./path/to/si-nixos-configuration.nix];"
  # 8) rebuild your NixOS configuration
  # 9) continue following the README instructions
  # ==================================

  # Install base packages needed for installation and data collection
  environment.systemPackages = with pkgs; [
    ansible
    bash
    curl
    dmidecode
    git
    jq
    lshw
  ];

  # Install and setup the antivirus
  services.clamav.daemon.enable = true;
  services.clamav.scanner.enable = true;
  services.clamav.updater.enable = true;

  # Install and setup compliance data collection
  systemd.services."collect_compliance_data" = {
    enable = true;
    description = "Collect Compliance Data";
    unitConfig = {
      Type = "simple";
    };
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "/etc/si-device-compliance/collect_compliance_data.sh /etc/si-device-compliance/token.txt";
      StandardOutput = append:/etc/si-device-compliance/logs/run.log;
      StandardError = append:/etc/si-device-compliance/logs/run.log;
    };
  };

  # Run compliance data collection on boot
  systemd.timers."collect_compliance_data" = {
    enable = true;
    description = "Timer to run compliance data collection 10 minutes after boot";
    timerConfig = {
      OnBootSec = "10min";
      Unit = "collect_compliance_data.service";
    };
    wantedBy = ["timers.target"];
  };

  # Run compliance data collection monthly
  systemd.timers."collect_compliance_data_monthly" = {
    enable = true;
    description = "Timer to run compliance data collection every month";
    timerConfig = {
      OnCalendar = "monthly";
      Unit = "collect_compliance_data.service";
    };
    wantedBy = ["timers.target"];
  };
}
