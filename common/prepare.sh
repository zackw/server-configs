# Server prep: common code.
# Do not invoke directly, use ./prepare-server in the parent directory.

datadir="$1"
workdir="$2"

# Verify that the base system is as we expect.
case "$(lsb_release -is):$(lsb_release -rs)" in
    (Ubuntu:18.04*) ;;
    (*) echo "Expected to be run on Ubuntu 18.04." >&2
        if [ ! -f /etc/debian_version ]; then
            echo "This doesn't appear to be a Debian-based system." >&2
        fi
        exit 1
        ;;
esac

# Clear out stuff installed by default which we do not need.
DESIRED_BASE_PKGS="ubuntu-standard ubuntu-server ubuntu-minimal"
DESIRED_BASE_PKGS="$DESIRED_BASE_PKGS linux-generic language-pack-en"

apt-mark auto $(apt-mark showmanual)
apt-mark manual $DESIRED_BASE_PKGS
apt-get --purge -y autoremove

# Perform any pending system updates.
apt-get update
apt-get -y upgrade

# Install additional packages.
DESIRED_ADD_PKGS="build-essential chrony"

apt-get -y install $DESIRED_ADD_PKGS

# Disable systemd's built-in NTP daemon (after reboot),
# since we are using chrony, which provides better clock stability.
systemctl disable systemd-timesyncd
systemctl mask systemd-timesyncd

# Configure unattended-upgrades.
(
    cd /etc/apt/apt.conf.d
    ln -s ../../../usr/share/unattended-upgrades/20auto-upgrades .
    sed -i.orig -e '
        /Unattended-Upgrade::Remove-Unused-Kernel-Packages /{
           s|^//||
           s|"false"|"true"|
        }
        /Unattended-Upgrade::Remove-Unused-Dependencies /{
           s|^//||
           s|"false"|"true"|
        }
        /Unattended-Upgrade::Automatic-Reboot /{
           s|^//||
           s|"false"|"true"|
        }
    ' 50unattended-upgrades
)

# Configure firewalling.  Inbound SSH connections are allowed,
# but rate limited.
ufw allow ssh
ufw limit ssh
ufw enable

# Slight adjustments to sshd configuration.
(
    cd /etc/ssh
    sed -i.orig -e '
        /PasswordAuthentication /{
          s/^#//
          s/ yes$/ no/
        }
    ' sshd_config
    sshd -t
)
