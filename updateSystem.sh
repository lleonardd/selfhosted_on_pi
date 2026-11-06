#!/bin/bash
# Weekly OS package upgrade (apt update && apt full-upgrade).
# Runs from cron right after updateAll.sh; StatusMails/docker_status_email.sh
# reads the summary file written here and puts it in the weekly status mail.
export PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin
export LC_ALL=C   # stable sort order for join, and English apt output to parse
# No prompts, and no apt-listchanges pager, when apt runs from cron.
apt_env=(DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none LC_ALL=C)

summary=/home/pi/services/updateSystem.summary
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Wait up to 15 min for apt-daily or a manual apt run; keep existing config files
# instead of prompting when a package ships a new default one.
apt_opts=(-y -q -o DPkg::Lock::Timeout=900
          -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)

installed_pkgs() {
    dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package} ${Version}\n' \
        | awk '$1=="ii" {print $2, $3}' | sort -k1,1
}

echo "Starting system update at $(date)"
printf 'status=running\nstarted=%s\n' "$(date '+%a %d %b %H:%M')" > "$summary"

installed_pkgs > "$tmp/before"

sudo -n "${apt_env[@]}" apt-get "${apt_opts[@]}" update 2>&1 | tee "$tmp/apt.log"
update_rc=${PIPESTATUS[0]}
sudo -n "${apt_env[@]}" apt-get "${apt_opts[@]}" full-upgrade 2>&1 | tee -a "$tmp/apt.log"
upgrade_rc=${PIPESTATUS[0]}
kept_back=$(grep -Eo '[0-9]+ not upgraded' "$tmp/apt.log" | tail -1 | cut -d' ' -f1)

# Drop packages nothing needs any more (mostly old kernels + headers; apt always
# keeps the running and the newest kernel), then the downloaded .deb cache.
sudo -n "${apt_env[@]}" apt-get "${apt_opts[@]}" autoremove 2>&1 | tee -a "$tmp/apt.log"
autoremove_rc=${PIPESTATUS[0]}
sudo -n "${apt_env[@]}" apt-get -q clean

installed_pkgs > "$tmp/after"

# Diff the package lists rather than parsing apt's prose: exact even if apt
# ran several transactions.
upgraded=$(join "$tmp/before" "$tmp/after" | awk '$2 != $3 {print $1}' | tr '\n' ' ')
new=$(join -v2 "$tmp/before" "$tmp/after" | cut -d' ' -f1 | tr '\n' ' ')
removed=$(join -v1 "$tmp/before" "$tmp/after" | cut -d' ' -f1 | tr '\n' ' ')
count() { set -- $1; echo $#; }

warnings=$(grep -cE '^(W|E|Err):' "$tmp/apt.log")
# Repos apt update could not refresh (e.g. an expired signing key); old indexes are used.
failed_repos=$(grep -Eo '^(W|E): Failed to fetch https?://[^/ ]+' "$tmp/apt.log" | sed 's|.*://||' | sort -u | tr '\n' ' ')

# A new kernel or firmware only takes effect after a reboot, which is left to you.
reboot=no
if [ -e /var/run/reboot-required ] ||
   printf '%s\n' $upgraded $new | grep -qE '^(linux-image|raspi-firmware|raspberrypi-kernel|raspberrypi-bootloader)'; then
    reboot=yes
fi

# Upgrading Docker restarts the daemon and with it every container at once. Home
# Assistant then comes up before OTBR is ready and loses Thread, so restart it
# once more after OTBR has settled, same as updateHomeassistant.sh does.
if printf '%s\n' $upgraded $new | grep -qE '^(docker-ce|containerd(\.io)?|docker\.io)$'; then
    echo "Docker was upgraded; waiting 60 s for OTBR, then restarting Home Assistant..."
    sleep 60
    docker restart homeassistant
fi

if [ "$update_rc" -eq 0 ] && [ "$upgrade_rc" -eq 0 ] && [ "$autoremove_rc" -eq 0 ]; then
    status=ok; else status=failed; fi

cat > "$summary" <<EOF
status=$status
update_rc=$update_rc
upgrade_rc=$upgrade_rc
autoremove_rc=$autoremove_rc
disk_free=$(df -h --output=avail / | tail -1 | tr -d ' ')
finished=$(date '+%a %d %b %H:%M')
finished_epoch=$(date +%s)
upgraded=$(count "$upgraded")
new=$(count "$new")
removed=$(count "$removed")
kept_back=${kept_back:-0}
warnings=$warnings
failed_repos=$failed_repos
reboot=$reboot
upgraded_list=$upgraded
new_list=$new
removed_list=$removed
EOF

echo "System update finished at $(date): status=$status, $(count "$upgraded") upgraded," \
     "$(count "$new") new, $(count "$removed") removed, reboot recommended: $reboot"
