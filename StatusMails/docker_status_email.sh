
# Set your email address
recipient="hallovonleo@gmail.com"

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
</style>
"

# Create the HTML content
html_content="<html><head>${css_styles}</head><body><h2>Docker Container Status</h2><table><tr><th>Name</th><th>Image</th><th>Status</th></tr>${docker_table}</table></body></html>"

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
