
# Set your email address
recipient="hallovonleo@gmail.com"

# Summary written by ../updateSystem.sh (apt full-upgrade, runs after updateAll.sh)
summary="${UPDATE_SUMMARY:-/home/pi/services/updateSystem.summary}"
get() { sed -n "s/^$1=//p" "$summary" 2>/dev/null; }

# If the system update is still busy when this mail is due, wait for it (max 60 min)
waited=0
while [ "$(get status)" = running ] && [ "$waited" -lt 60 ]; do
  sleep 60
  waited=$((waited + 1))
done

# "a b c ..." -> "a, b, c ... and N more" (first 10 names only, to keep the mail short)
brief_list() {
  printf '%s\n' $1 | awk -v max=10 'NF { n++; if (n <= max) out = out (n > 1 ? ", " : "") $0 }
    END { if (n > max) out = out " and " n - max " more"; print out }'
}

# Generate the system update section
finished_epoch=$(get finished_epoch)
if [ ! -f "$summary" ]; then
  system_html="<p>No system update has run yet.</p>"
elif [ "$(get status)" = running ]; then
  system_html="<p class='warn'>The system update started $(get started) is still running (or was interrupted) - see ~/services/updateSystem.log</p>"
elif [ -z "$finished_epoch" ] || [ $(( $(date +%s) - finished_epoch )) -gt 86400 ]; then
  system_html="<p class='warn'>No system update ran this week (last one finished $(get finished)).</p>"
else
  system_html="<p><b>$(get upgraded)</b> packages upgraded, <b>$(get new)</b> newly installed, <b>$(get removed)</b> removed"
  [ "$(get kept_back)" -gt 0 ] 2>/dev/null && system_html="$system_html, <b>$(get kept_back)</b> kept back"
  system_html="$system_html (finished $(get finished)).</p>"
  [ -n "$(get disk_free)" ] && system_html="$system_html<p class='small'>Root disk: $(get disk_free) free after autoremove + clean.</p>"

  if [ "$(get status)" != ok ]; then
    system_html="$system_html<p class='bad'><b>apt failed</b> (update exit $(get update_rc), full-upgrade exit $(get upgrade_rc), autoremove exit $(get autoremove_rc)) - see ~/services/updateSystem.log</p>"
  fi
  if [ "$(get reboot)" = yes ]; then
    system_html="$system_html<p class='warn'><b>Reboot recommended</b> - a new kernel or firmware was installed.</p>"
  fi
  if [ -n "$(get failed_repos)" ]; then
    system_html="$system_html<p class='warn'>Could not refresh: $(get failed_repos)(old package lists used) - see ~/services/updateSystem.log</p>"
  elif [ "$(get warnings)" -gt 0 ] 2>/dev/null; then
    system_html="$system_html<p class='small'>$(get warnings) apt warning/error lines - see ~/services/updateSystem.log</p>"
  fi
  [ -n "$(get upgraded_list)" ] && system_html="$system_html<p class='small'>Upgraded: $(brief_list "$(get upgraded_list)")</p>"
  [ -n "$(get new_list)" ] && system_html="$system_html<p class='small'>New: $(brief_list "$(get new_list)")</p>"
  [ -n "$(get removed_list)" ] && system_html="$system_html<p class='small'>Removed: $(brief_list "$(get removed_list)")</p>"
fi

# Generate a Docker HTML table
docker_table=$(docker ps --format '<tr><td>{{.Names}}</td><td>{{.Image}}</td><td>{{.Status}}</td></tr>')

# Define the CSS styles
css_styles="
<style>
  table {
    border-collapse: collapse;
    width: 100%;
  }
  th, td {
    border: 1px solid black;
    padding: 10px;
  }
  th {
    background: lightgrey;
  }
  .warn { color: #b36b00; }
  .bad { color: #c00000; }
  .small { font-size: smaller; color: #555; }
</style>
"

# Create the HTML content
html_content="<html><head>${css_styles}</head><body><h2>Docker Container Status</h2><table><tr><th>Name</th><th>Image</th><th>Status</th></tr>${docker_table}</table><h2>System Updates</h2>${system_html}</body></html>"

# Create a temporary HTML file
html_file="/tmp/docker_status.html"
echo "$html_content" > "$html_file"

# Use sendmail to send the email
sendmail "$recipient" <<EOF
Subject: Pi4 - Docker Container Status
To: $recipient
Content-Type: text/html
MIME-Version: 1.0

$html_content
EOF

# Remove the temporary HTML file
rm "$html_file"
