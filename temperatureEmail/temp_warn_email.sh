

# Get the CPU temperature in millidegrees Celsius
cpu_temp=$(</sys/class/thermal/thermal_zone0/temp)
cpu_temp=$((cpu_temp/1000))  # Convert to degrees Celsius

# Define the threshold temperature
threshold=70

# Check if the CPU temperature exceeds the threshold
if [ $cpu_temp -gt $threshold ]; then
  # Send an email notification using sendmail
  email_subject="Raspberry Pi 4 - High CPU Temperature Warning"

  email_body+="<html><body>"
  email_body+="<div style=\"font-family: Arial, sans-serif; background-color: #ffcccc; padding: 10px; border-radius: 5px;\">"
  email_body+="<h3 style=\"color: #333333;\">High CPU Temperature Warning</h3>"
  email_body+="<p style=\"color: #666666; line-height: 1.5;\">The CPU temperature has exceeded ${threshold}°C.</p>"
  email_body+="<p style=\"color: #666666; line-height: 1.5;\">Current temperature: <span style=\"font-weight: 900;\">${cpu_temp}°C</span>.</p>"
  email_body+="</div>"
  email_body+="</body></html>"

  recipient_email="hallovonleo@gmail.com"

  echo -e "Subject:$email_subject\nContent-Type: text/html\n\n$email_body" | sendmail "$recipient_email"
fi
