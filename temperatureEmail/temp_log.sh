echo "$(date +"Date: %d.%m.%Y - Time: %T")  =>  $(vcgencmd measure_temp)" >> /tmp/tempList.txt

tail --lines=50 /tmp/tempList.txt > /tmp/newfile && mv /tmp/newfile /tmp/tempList.txt
