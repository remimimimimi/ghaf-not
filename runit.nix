{ pkgs, lib, config, ... }:

let
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
  nginx_http_config = pkgs.writeText "nginx_http_config" ''
    user nobody nogroup;
    worker_processes  1;
    daemon off;

    error_log  /var/log/http/error.log warn;
    pid        /var/run/http.pid;

    events {
      worker_connections  1024;
    }

    http {
      log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent" "$http_x_forwarded_for"';
      access_log /var/log/http/access.log main;
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
          root  /var/www/noteed.com;
          index  index.html;
        }
      }
    }
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
        listen 443;
        server_name noteed.com;
        ssl on;
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
in
{
  environment.systemPackages = [ compat pkgs.socat ];
  environment.etc = {
    "runit/1".source = pkgs.writeScript "1" ''
      #!${pkgs.stdenv.shell}
      mkdir /bin/
      ln -s ${pkgs.stdenv.shell} /bin/sh

      # disable DPMS on tty's
      echo -ne "\033[9;0]" > /dev/tty0

      touch /etc/runit/stopit
      chmod 0 /etc/runit/stopit

      ${if config.not-os.simpleStaticIp then ''
        echo Setting static IP address...
        ip addr add 10.0.2.15 dev eth0
        ip link set eth0 up
        ip route add 10.0.2.0/24 dev eth0
        ip route add default via 10.0.2.2 dev eth0
      '' else ''
        echo Setting dynamic IP address...
        touch /etc/dhcpcd.conf
        mkdir -p /var/db/dhcpcd
        ip link set up eth0
        ${pkgs.dhcpcd}/sbin/dhcpcd eth0 -4 --waitip
      ''}

      echo Running ntpdate...
      ${pkgs.ntp}/bin/ntpdate pool.ntp.org

      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      mkdir -p /var/dehydrated
      echo Registering to letsencrypt...
      ${pkgs.dehydrated}/bin/dehydrated --config /etc/letsencrypt/dehydrated.conf --register --accept-terms

      # For Nginx
      mkdir -p /var/log/{http,https} /var/run
    '';
    "runit/2".source = pkgs.writeScript "2" ''
      #!/bin/sh
      # cat /proc/uptime

      # Create the runlevels.
      mkdir -p /etc/runit/runsvdir/http-only
      mkdir -p /etc/runit/runsvdir/https-too

      ln -s /etc/sv/rngd /etc/runit/runsvdir/http-only/rngd
      ln -s /etc/sv/sshd /etc/runit/runsvdir/http-only/sshd
      ln -s /etc/sv/http /etc/runit/runsvdir/http-only/http

      ln -s /etc/sv/rngd /etc/runit/runsvdir/https-too/rngd
      ln -s /etc/sv/sshd /etc/runit/runsvdir/https-too/sshd
      ln -s /etc/sv/https /etc/runit/runsvdir/https-too/https

      echo Running runsvdir...
      ln -s http-only /etc/runit/runsvdir/current
      ln -s /etc/runit/runsvdir/current /etc/service
      runsvchdir http-only
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
    "sv/http/run".source = pkgs.writeScript "http_run" ''
      #!/bin/sh
      echo Running Nginx HTTP...
      exec ${pkgs.nginx}/bin/nginx -c ${nginx_http_config}
    '';
    # This will fail if there is no SSL certificate and key.
    "sv/https/run".source = pkgs.writeScript "https_run" ''
      #!/bin/sh
      echo Running Nginx HTTPS...
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
  };
}
