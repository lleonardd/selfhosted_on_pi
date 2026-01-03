echo Subject: Temperaturliste RaspberryPi 4
echo
echo Sending at $(date) @ $(hostname)
echo ---------------------------------

tail --lines=50 /tmp/tempList.txt > /tmp/newfile && mv /tmp/newfile /tmp/tempList.txt

cat /tmp/tempList.txt
