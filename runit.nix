{
  pkgs,
  lib,
  config,
  ...
}: let
  sshd_config = pkgs.writeText "sshd_config" ''
    HostKey /etc/ssh/ssh_host_rsa_key
    HostKey /etc/ssh/ssh_host_ed25519_key
    Port 22
    PidFile /run/sshd.pid
    Protocol 2
    PermitRootLogin yes
    PasswordAuthentication yes
    AuthorizedKeysFile /etc/ssh/authorized_keys.d/%u
  '';
  nginx_https_config = pkgs.writeText "nginx_https_config" ''
    user nobody nogroup;
    worker_processes  1;
    daemon off;

    error_log  /var/log/https/error.log warn;
    pid        /var/run/https.pid;

    events {
      worker_connections  1024;
    }

    http {
      log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent" "$http_x_forwarded_for"';
      access_log /var/log/https/access.log main;
      server_names_hash_bucket_size  64;

      include ${pkgs.nginx}/conf/mime.types;
      default_type  application/octet-stream;

      sendfile           on;
      keepalive_timeout  65;

      server {
        listen 80;
        server_name noteed.com;

        add_header X-Robots-Tag "noindex, nofollow, nosnippet, noarchive";

        location /robots.txt {
            default_type text/plain;
            return 200 'User-agent: *\nDisallow: /';
        }
        location /.well-known {
          root  /var/www/acme;
          index  index.html;
        }
        location / {
          return 301 https://$host$request_uri;
        }
      }

      server {
        listen 443 ssl;
        server_name noteed.com;
        ssl_certificate /var/dehydrated/certs/noteed.com/fullchain.pem;
        ssl_certificate_key /var/dehydrated/certs/noteed.com/privkey.pem;

        add_header X-Robots-Tag "noindex, nofollow, nosnippet, noarchive";

        location /robots.txt {
            default_type text/plain;
            return 200 'User-agent: *\nDisallow: /';
        }
        location / {
          root  /var/www/noteed.com;
          index  index.html;
        }
      }
    }
  '';
  compat = pkgs.runCommand "runit-compat" {} ''
        mkdir -p $out/bin/
        cat << EOF > $out/bin/poweroff
    #!/bin/sh
    exec runit-init 0
    EOF
        cat << EOF > $out/bin/reboot
    #!/bin/sh
    exec runit-init 6
    EOF
        chmod +x $out/bin/{poweroff,reboot}
  '';
in {
  environment.systemPackages = [compat pkgs.socat];
  environment.etc = {
    "runit/1".source = pkgs.writeScript "1" ''
      #!${pkgs.stdenv.shell}
      mkdir /bin/
      ln -s ${pkgs.stdenv.shell} /bin/sh

      # disable DPMS on tty's
      echo -ne "\033[9;0]" > /dev/tty0

      touch /etc/runit/stopit
      chmod 0 /etc/runit/stopit

      ${
        if config.not-os.simpleStaticIp
        then ''
          echo Setting static IP address...
          ip addr add 10.0.2.15 dev eth0
          ip link set eth0 up
          ip route add 10.0.2.0/24 dev eth0
          ip route add default via 10.0.2.2 dev eth0
        ''
        else ''
          echo Setting dynamic IP address...
          touch /etc/dhcpcd.conf
          mkdir -p /var/db/dhcpcd
          ip link set up eth0
          ${pkgs.dhcpcd}/sbin/dhcpcd eth0 -4 --waitip
        ''
      }

      echo Running ntpdate...
      ${pkgs.ntp}/bin/ntpdate pool.ntp.org

      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      mkdir -p /var/dehydrated
      # Do this only in the cloud.
      ${
        if config.not-os.cloud-init
        then ''
          echo Registering to letsencrypt...
          ${pkgs.dehydrated}/bin/dehydrated --config /etc/letsencrypt/dehydrated.conf --register --accept-terms
        ''
        else ''
        ''
      }

      # For Nginx
      mkdir -p /var/log/https /var/run /var/dehydrated/certs/noteed.com/
      cp /etc/self-signed/fullchain.pem /var/dehydrated/certs/noteed.com/
      cp /etc/self-signed/privkey.pem /var/dehydrated/certs/noteed.com/

      # Pseudo cloud config: copy the public SSH key in place.
      ${
        if config.not-os.cloud-init
        then ''
          echo Reading config-2 drive to set the root public SSH key...
          mkdir /mnt
          mount /dev/vdb /mnt
          mkdir -p /etc/ssh/authorized_keys.d/
          cat /mnt/openstack/latest/meta_data.json | \
            ${pkgs.jq}/bin/jq -r '.public_keys."0"' > \
            /etc/ssh/authorized_keys.d/root
          umount /mnt
        ''
        else ''
        ''
      }
    '';
    "runit/2".source = pkgs.writeScript "2" ''
      #!/bin/sh
      # cat /proc/uptime

      # Create the runlevels.
      mkdir -p /etc/runit/runsvdir/https-too

      ln -s /etc/sv/rngd /etc/runit/runsvdir/https-too/rngd
      ln -s /etc/sv/sshd /etc/runit/runsvdir/https-too/sshd
      ln -s /etc/sv/https /etc/runit/runsvdir/https-too/https

      echo Running runsvdir...
      ln -s https-too /etc/runit/runsvdir/current
      ln -s /etc/runit/runsvdir/current /etc/service
      runsvchdir https-too
      exec runsvdir -P /etc/service
    '';
    "runit/3".source = pkgs.writeScript "3" ''
      #!/bin/sh
      echo Shutting down...
    '';
    "sv/sshd/run".source = pkgs.writeScript "sshd_run" ''
      #!/bin/sh
      echo Running sshd...
      exec ${pkgs.openssh}/bin/sshd -D -f ${sshd_config}
    '';
    "sv/rngd/run".source = pkgs.writeScript "rngd" ''
      #!/bin/sh
      echo Running rngd...
      export PATH=$PATH:${pkgs.rng_tools}/bin
      exec rngd -f -r /dev/hwrng
    '';
    #"sv/nix/run".source = pkgs.writeScript "nix" ''
    #  #!/bin/sh
    #  echo Running nix-daemon...
    #  nix-store --load-db < /nix/store/nix-path-registration
    #  nix-daemon
    #'';
    # This will fail if there is no SSL certificate and key.
    "sv/https/run".source = pkgs.writeScript "https_run" ''
      #!/bin/sh
      echo Running Nginx HTTPS...
      mkdir -p /var/log/nginx /var/cache/nginx
      exec ${pkgs.nginx}/bin/nginx -c ${nginx_https_config}
    '';
    #"sv/autohalt/run".source = pkgs.writeScript "autohalt" ''
    #  #!/bin/sh
    #  for i in 1 2 3 4 5 6 7 8 9 10; do
    #    echo $i
    #    sleep 10
    #  done
    #  runit-init 0
    #'';

    # Self-signed certificate. This is normally replaced by a Let's encrypt
    # certificate once the image runs.
    "self-signed/fullchain.pem".source = pkgs.writeScript "fullchain.pem" ''
      -----BEGIN CERTIFICATE-----
      MIIGITCCBAmgAwIBAgIJALDa08Isxd/0MA0GCSqGSIb3DQEBCwUAMIGmMQswCQYD
      VQQGEwJCRTEOMAwGA1UECAwFTmFtdXIxDzANBgNVBAcMBkphbWJlczEVMBMGA1UE
      CgwMSHlwZXJlZCBTUFJMMR0wGwYDVQQLDBRTb2Z0d2FyZSBEZXZlbG9wbWVudDEh
      MB8GA1UEAwwYdW5wcm92aXNpb25lZC5oeXBlcmVkLmJlMR0wGwYJKoZIhvcNAQkB
      Fg50aHVAaHlwZXJlZC5pbzAeFw0xOTA5MTMxNjE1NTNaFw0yOTA5MTAxNjE1NTNa
      MIGmMQswCQYDVQQGEwJCRTEOMAwGA1UECAwFTmFtdXIxDzANBgNVBAcMBkphbWJl
      czEVMBMGA1UECgwMSHlwZXJlZCBTUFJMMR0wGwYDVQQLDBRTb2Z0d2FyZSBEZXZl
      bG9wbWVudDEhMB8GA1UEAwwYdW5wcm92aXNpb25lZC5oeXBlcmVkLmJlMR0wGwYJ
      KoZIhvcNAQkBFg50aHVAaHlwZXJlZC5pbzCCAiIwDQYJKoZIhvcNAQEBBQADggIP
      ADCCAgoCggIBAN1u5uBFOYU4lsYMRiymLEynqvJ4BXGMmkIop9GEs2RhF3wCT52A
      0qJ1h2E1N5iGRBUkilojQTh/nqjncqjgPCOD20KvzzO3UlC4UPY0BnUv269So6Lc
      vVB4F9zxHbnerr1wAbt9z/J954hihIsULdPf9V8hSAhDZWXyhs1qDT6UcnqUASHr
      xMA0z4dwy8UPpPqBMkQDbjnt0R7T85bdugVGw4PZS2aG9HHmhORhoODLVLqiM/79
      jWAbbUoQVrOYtxIyRZAQvgLP4NakDJYeL3HKRJON8FozxrsRY3daaaQzRpQPCjOO
      mxRS95F7oXg185QddWFdqLkyuRivpoCo3Np9wWqkd7/HToIEgdALiVQupYcGweBV
      SO86XqULrteGiKVNA9yX45Fa9gvre5GF5kSHZOcRFYBzuCMaJj48XtsGMjslTzwa
      h9yWb7J0p8cawNTj6T2a2xgVs9em+j9NVraiBBAQlKHnB3qA+yMneMcna+0xTEpP
      w8dqIpH5Kk6t/m0clBVDBbj75pdUy/hV/w0j2+joKyQylgLANFzgdhbBKdpWBWJ9
      S0HRT/vZHBGlJHvvOyDl8mEoKlWzQWzxXYltQ7jA993CoPchqXuLJrJsUIUa6D2G
      E1TWKfAiDLi7jcP7XRIh1YZo3fs9BQ6hzfQcTlec9IqbNk1x/b2d0VbJAgMBAAGj
      UDBOMB0GA1UdDgQWBBSdjpgM0Uo7YG89MhmudoYfFCCAFzAfBgNVHSMEGDAWgBSd
      jpgM0Uo7YG89MhmudoYfFCCAFzAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUA
      A4ICAQASFegYMmBTGLXJ05NxJZlNirPMSaQBrMPOqc+qWWnEJtKUwGvbOGiSWLx1
      Gb4I4Asll5Cirk/EM1DPAz94H/C8jdccqnT4X/lv0GSormz+NyfYN0c75kyLbPX+
      tbwG1SKCsUar5UkLCuJ8gD4D+J23Fe3DssHfptQevCfQ1GEUrtjVzWpNQVPVk0cg
      kdBYKDxO1f4D3gCFByZNY06pL2I+PvK+v61XepUJ6SEmFXxE1H3rhSyEzEmHXKft
      QcXowQAxK3IfHWcb1NcTaZeD71kAFjaMsyAlI5KxHDBNF6KSrWFyrOSjY6yILxFD
      eKEkQ+0n+VkqBx2S802/mFUk/DqrNbxBMI4Kng0IeiMoa3aY2MX8ytfcGNKLBwM6
      2x5HUq6jpAUEuc+up/xjMatSLzFhvEXhWryCLprZnjJe+q7B/jGoA0mWX5gvielj
      p3Go3pDmlMjSO7iuQpHtE8uPbI2MfDXht1DnsCdbpVTucHPQSdOa3conucpB3LuY
      qU4VqoEHE+96ekKTuwkdyIxHomhqM48xGDnJSkTFpkIBq6KgHDT252rSSR8AA6iJ
      M5H6hxhi4nuk4Y0DhwlIFf1DT+o7MuFN92SZJaN5UcrAm1+p7em3PPxRkFUyW+6X
      Yh7xiaFqIG2OxsCyKPSx0ZKK6ymxGPcOOlqLPIcnhfb1tYzLrQ==
      -----END CERTIFICATE-----
    '';
    "self-signed/privkey.pem".source = pkgs.writeScript "privkey.pem" ''
      -----BEGIN PRIVATE KEY-----
      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
      6k1f0nlRfEIY9sCJE2ZO6dO9T82qN+g=
      -----END PRIVATE KEY-----
    '';
  };
}
