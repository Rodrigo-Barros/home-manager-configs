{config,pkgs,...}:
let

  # install flatpak files in user space
  notification = pkgs.writeScriptBin "flatpakUserSpace" ''
  #!${pkgs.bash}/bin/bash
  applicativo="$1"
  start_msg="Iniciando instalação do aplicativo"
  notification_id=$(${pkgs.notify-desktop}/bin/notify-desktop -i firefox "Download Manager:" "$start_msg")
  
  msg=$((flatpak --user install $applicativo -y) 2>&1)
  echo $msg | grep instalado
  instalado=$?
  if [ $instalado -eq 0 ];then
    finish_msg="O Aplicativo já foi instalado"
  else
    finish_msg="Aplicativo instalado"
  fi
  #finish_msg="$msg"

  ${pkgs.notify-desktop}/bin/notify-desktop -r $notification_id -i firefox "Download Manager:" "$finish_msg"
 
  '';

  desktopEntry = pkgs.writeTextFile {
    name = "flatpakUserSpace";
    destination = "/share/applications/flatpak-user-space.desktop";
    text = ''
    [Desktop Entry]
    Name=Flatpak User Installer
    Icon=firefox
    Type=Application
    Terminal=false
    MimeType=application/vnd.flatpak.ref
    Exec=${notification}/bin/flatpakUserSpace %f
    '';     
  };

  flatpakUserSpace = pkgs.buildEnv {
    name = "Flatpak User Space";
    #version = "0.1aplha";
    paths = [ 
      notification
      desktopEntry
    ];
    pathsToLink = [ "/share/applications" "/bin" ];
  };
in
{
  home.username = "rodrigo";
  home.homeDirectory = "/home/rodrigo";
  home.packages = with pkgs;[
    hello
    chiaki
    google-chrome
    audacity
    flatpakUserSpace
    gnome-randr
  ];

  # Desabilita os modulos especificados
  # Ideal para desenvolvimento
  disabledModules = [
    "programs/firefox.nix"
  ];

  # load custom modules
  imports = [
    ./modules/nixgl.nix
    ./modules/firefox.nix
    ./modules/rclone.nix
    ./modules/android.nix
  ];

  # link the folders passed to array/list to  ~/.nix-profile/share/doc
  # at least I guess.
  home.extraOutputsToInstall = [ "doc" ];

  home.stateVersion = "22.05";

  programs.nixGL.enable = true;

  programs.firefox = 
  {
    enable = true;
    # extensions = with pkgs.nur.repos.rycee.firefox-addons; [ 
    #   i-dont-care-about-cookies
    # ];
    profiles.rodrigo.handlers = {
      mimeTypes = {
        "application/vnd.flatpak.ref" = {
          action = 2;
          extensions = [
            "flatpakref"
            "flatpak.ref"
          ];
          handlers = [
            {
              name = "flatpak-user-installer";
              path = "${notification}/bin/flatpakUserSpace";
            }
          ];
        };
      };
    };
    profiles.rodrigo.isDefault = true;
    profiles.rodrigo.settings = {
      "intl.locale.requested" = "pt-BR,en-US";
      "browser.shell.defaultBrowserCheckCount" = 0;
    };
    profiles.rodrigo.search.force = true;
    profiles.rodrigo.search.default = "Google";
    profiles.rodrigo.search.engines = {
      "Nix Packages" = {
        urls = [
          {
            template = "https://search.nixos.org/packages";
            params = [
              { name = "type"; value = "packages"; }
              { name = "query"; value = "{searchTerms}"; }
            ];
          }
        ];
        icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        definedAliases = [ "@np" ];
      };

      "Home Manager Options" = {
        urls = [ 
          {
            template = "https://mipmip.github.io/home-manager-option-search/?{searchTerms}";
          }
        ];
        iconUpdateURL = "https://mipmip.github.io/home-manager-option-search/images/favicon.png";
        updateInterval = 24 * 60 * 60 * 1000; # every day
        definedAliases = [ "@hm-op" ];
      };

      "Youtube Channels" = {
        urls = [ 
          {
            template = "https://www.youtube.com/{searchTerms}";
          }
        ];
        iconUpdateURL = "https://www.youtube.com/s/desktop/25bf5aae/img/favicon_144x144.png";
        updateInterval = 24 * 60 * 60 * 1000; # every day
        definedAliases = [ "@yt" ];
      };

      Google.metaData.alias = "@g";
    };

    # maybe I try use this in near future
    # package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
    #   extraPolicies = {
    #     Handlers = {
    #       mimeTypes = {
    #         "application/vnd.flatpak.ref" = {
    #           action = "useSystemDefault";
    #           ask = true;
    #         };
    #       };
    #     };
    #   };
    # };

  }; 

  android-sdk = {
    enable = true;
    packages = (sdk: with sdk;[
      cmdline-tools-latest

      build-tools-30-0-3
      platform-tools

      # needed to build flutter app
      patcher-v4

      emulator

      # talvez não precise desse pacote
      platforms-android-28


      platforms-android-31
      system-images-android-28-google-apis-playstore-x86-64
    ]);
  };
  programs.rclone.enable = true;
  programs.rclone.sync_strategy = "copy";
  programs.rclone.providers = {
    gdrive = {
      local_folder = "/run/media/rodrigo/share/Meus Documentos";
      remote_folder = "gdrive:sync";
    };
    onedrive = {
      local_folder = "/run/media/rodrigo/share/Meus Documentos";
      remote_folder = "onedrive:sync";
    };
  };

  # custom modules
  xdg.desktopEntries = {
    "chiaki" = {
      name = "Chiaki (nix)";
      icon = "chiaki";
      exec = "nixGLIntel chiaki";
      terminal = false;
    };
    
    "firefox_nix" = {
      name = "Firefox (nix)";
      icon = "firefox";
      exec = "nixGLIntel ${pkgs.firefox}/bin/firefox --class \"Firefox (nix)\" %u";
      terminal = false;
      type = "Application";
      startupNotify = true;
      settings = {
        StartupWMClass = "Firefox (nix)";
      };
      actions = {
        "new-window" = {
          name = "Nova janela";
          exec = "${pkgs.firefox}/bin/firefox --class \"Firefox (nix)\" --new-window %u";
        };
        "new-private-window" = {
          name = "Nova janela anônima";
          exec = "${pkgs.firefox}/bin/firefox --class \"Firefox (nix)\" --private-window %u";
        };
      };
    };

    "firefox" = {
      name = "Firefox (system)";
      icon = "firefox";
      exec = "/usr/bin/firefox --class \"Firefox (system)\" %u";
      terminal = false;
      startupNotify = true;
      type = "Application";
      settings = {
        StartupWMClass = "Firefox (system)";
      };
      actions = {
        "new-window" = {
          name = "Nova janela";
          exec = "/usr/bin/firefox --class \"Firefox (system)\" --new-window %u";
        };
        "new-private-window" = {
          name = "Nova janela anônima";
          exec = "/usr/bin/firefox --class \"Firefox (system)\" --private-window %u";
        };
      };
    };
  };

  # fix desktop files not showing icons when switch generation
  home.activation = {
    linkDesktopApplications = {
      after = [ "writeBoundary" "createXdgUserDirectories" ];
      before = [ ];
      data = ''
        update-desktop-database 
      '';
    };
  };

  # fix desktop files not showing icons when switch generation
  # this setting idk if is necessary
  # run update-mime-database and update-mime-database
  xdg.mime.enable = true;

  xdg.mimeApps.enable = true;

  xdg.mimeApps.defaultApplications = {

    # same as xdg-settings set default-web-browser firefox_nix.desktop
    "x-scheme-handler/http"               = [ "firefox_nix.desktop" "firefox.desktop" ];
    "x-scheme-handler/https"              = [ "firefox_nix.desktop" "firefox.desktop" ];
    "x-scheme-handler/about"              = [ "firefox_nix.desktop" "firefox.desktop" ];
    "x-scheme-handler/unknow"             = [ "firefox_nix.desktop" "firefox.desktop" ];
    "x-scheme-handler/chrome"             = [ ];

    "text/html"                           = [ "firefox_nix.desktop" "firefox.desktop" ];

    "application/x-extension-htm"         = [ "firefox_nix.desktop" "firefox.desktop" ];
    "application/x-extension-html"        = [ "firefox_nix.desktop" "firefox.desktop" ];
    "application/x-extension-shtml"       = [ "firefox_nix.desktop" "firefox.desktop" ];
    "application/x-extension-xhtml+xml"   = [ "firefox_nix.desktop" "firefox.desktop" ];
    "application/x-extension-xhtml"       = [ "firefox_nix.desktop" "firefox.desktop" ];
    "application/x-extension-xht"         = [ "firefox_nix.desktop" "firefox.desktop" ];

    "application/vnd.flatpak.ref" = [ "flatpak-user-space.desktop" ];
  };
  # fix desktop files not showing icons when switch generation
  programs.bash = {
	  enable = true;
	  profileExtra = ''
    . $HOME/.nix-profile/etc/profile.d/nix.sh
    export XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"
    '';
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  services.home-manager.autoUpgrade = {
    enable = true;
    frequency = "weekly";
  };
}
