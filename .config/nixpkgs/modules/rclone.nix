{lib,config,pkgs,...}:
with lib;
let 
    cfg = config.programs.rclone;
in
{
    options.programs.rclone = {
        enable = mkEnableOption "Enable rclone";
        frequency = mkOption {
            description = "The frequency for sync files";
            type = types.str;
            default = "*:0/15";
            example = "*:0/15 this means the sync will occur every 15 minutes";
        };
        providers = mkOption {
            description = "basic config about files clouds, this setting only works after execute rclone config";
            type = types.attrs;
            example = lib.literalExpresion ''
                {
                    gdrive = {
                        local_folder = "/run/media/share/Google Drive";
                        remote_folder = "gdrive:";
                        sync_strategy = "copy"; # here you can customize the sync style by provider
                    };
                    onedrive = {
                        local_folder = "/run/media/rodrigo/share/Onedrive";
                        remote_folder = "onedrive:";
                        sync_strategy = "sync"; # I recommend use copy cause sync can delete files
                    };
                }
            '';
            default = {};
        };
        sync_strategy = mkOption {
            description = "sync strategy style the options are copy and sync";
            type = types.str;
            default = "copy";
        };
    };

    config = 
    let 
        create_services_files = cfg.enable && cfg.providers != {};
    in
    mkIf cfg.enable {
        home.packages = [ pkgs.rclone ];
        systemd.user.services.rclone = mkIf (create_services_files) {
            Unit.Description = "rclone sync service";
            Install.WantedBy = [ "default.target" ];
            Service.ExecStart = 
            let 
                service_file = pkgs.writeTextFile {
                    name = "systemd-service-helper";
                    executable = true;
                    text = "#!${pkgs.bash}/bin/bash\n" + builtins.concatStringsSep "\n" (
                        forEach (builtins.attrNames cfg.providers) (provider:
                            let
                                item = cfg.providers.${provider};
                                dest = if builtins.hasAttr "remote_folder" item then "${item.remote_folder}" else "${provider}:";
                            in
                            "${pkgs.rclone}/bin/rclone ${if builtins.hasAttr "sync_strategy" item then item.sync_strategy else cfg.sync_strategy} \"${item.local_folder}\" ${dest} --copy-links"
                        )
                    );
                };
            in 
            "${service_file}";
        };

        systemd.user.timers.rclone = mkIf create_services_files {
            Unit.Description = "rclone periodic sync";
            Timer = {
                Unit = "rclone.service";
                OnCalendar = cfg.frequency;
            };
            Install.WantedBy = [ "timers.target" ];
        };
    };
}