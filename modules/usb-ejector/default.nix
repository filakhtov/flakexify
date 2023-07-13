flake: { config, lib, pkgs, ... }:
let
  inherit (flake.packages.${pkgs.stdenv.hostPlatform.system}) usb-ejector;
  cfg = config.services.usb-ejector;
in
{
  options = {
    services.usb-ejector = {
      enable = lib.mkEnableOption ''
        Enable a USB-ejector service.
        This service provides an ability to automatically eject the USB drive
        once system is done booting.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."usb-ejector@" = {
      description = "Detach configured USB drive from the system";

      after = [ "local-fs.target" ];
      wantedBy = [ "multi-user.target" ];

      unitConfig = {
        conditionPathExists = "/dev/disk/by-partuuid/%I";
      };

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getBin usb-ejector}/bin/usb-ejector.sh";
      };
    };
  };
}
