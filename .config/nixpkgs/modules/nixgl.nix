{config,lib,pkgs,...}:
with lib;
let 
    cfg = config.programs.nixGL;
in
{
    options.programs.nixGL = {
        enable = mkEnableOption "nixGL wrapper";
        packages = mkOption {
            description = "NixGL Packages to add to your environment";
            type = types.listOf types.package;
            default = with pkgs.nixGL; [ nixGLIntel nixVulkanIntel ];
            example = literalExample "with pkgs.nixGL; [ nixGLIntel nixVulkanIntel ]";
        };
    };

    config = mkIf cfg.enable {
        home.packages = cfg.packages;
    };
}