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
  nginx_config = pkgs.writeText "nginx_config" ''
    user  nobody nogroup;
    worker_processes  1;
    daemon off;

    error_log  /var/log/nginx/error.log warn;
    pid        /var/run/nginx.pid;

    events {
      worker_connections  1024;
    }

    http {
      log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent" "$http_x_forwarded_for"';
      access_log /var/log/nginx/access.log main;
      server_names_hash_bucket_size  64;
      default_type  application/octet-stream;

      sendfile           on;
      keepalive_timeout  65;

      server {
        listen 80;
        server_name example.com;

        add_header X-Robots-Tag "noindex, nofollow, nosnippet, noarchive";

        location /robots.txt {
            default_type text/plain;
            return 200 'User-agent: *\nDisallow: /';
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
      ${lib.optionalString config.not-os.simpleStaticIp ''
      echo Setting static IP address...
      ip addr add 10.0.2.15 dev eth0
      ip link set eth0 up
      ip route add 10.0.2.0/24 dev eth0
      ip route add default via 10.0.2.2 dev eth0
      ''}
      mkdir /bin/
      ln -s ${pkgs.stdenv.shell} /bin/sh
      echo Running ntpdate...
      ${pkgs.ntp}/bin/ntpdate pool.ntp.org

      # disable DPMS on tty's
      echo -ne "\033[9;0]" > /dev/tty0

      touch /etc/runit/stopit
      chmod 0 /etc/runit/stopit
      ${if true then "" else "${pkgs.dhcpcd}/sbin/dhcpcd"}

      # For nginx
      mkdir -p /var/log/nginx /var/run
    '';
    "runit/2".source = pkgs.writeScript "2" ''
      #!/bin/sh
      # cat /proc/uptime
      echo Running runsvdir...
      exec runsvdir -P /etc/service
    '';
    "runit/3".source = pkgs.writeScript "3" ''
      #!/bin/sh
      echo Shutting down...
    '';
    "service/sshd/run".source = pkgs.writeScript "sshd_run" ''
      #!/bin/sh
      echo Running sshd...
      ${pkgs.openssh}/bin/sshd -D -f ${sshd_config}
    '';
    "service/rngd/run".source = pkgs.writeScript "rngd" ''
      #!/bin/sh
      echo Running rngd...
      export PATH=$PATH:${pkgs.rng_tools}/bin
      exec rngd -f -r /dev/hwrng
    '';
    "service/nix/run".source = pkgs.writeScript "nix" ''
      #!/bin/sh
      echo Running nix-daemon...
      nix-store --load-db < /nix/store/nix-path-registration
      nix-daemon
    '';
    "service/nginx/run".source = pkgs.writeScript "nginx_run" ''
      #!/bin/sh
      echo Running nginx...
      ${pkgs.nginx}/bin/nginx -c ${nginx_config}
    '';
    #"service/autohalt/run".source = pkgs.writeScript "autohalt" ''
    #  #!/bin/sh
    #  for i in 1 2 3 4 5 6 7 8 9 10; do
    #    echo $i
    #    sleep 10
    #  done
    #  runit-init 0
    #'';
  };
}
