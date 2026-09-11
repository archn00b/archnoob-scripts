echo "===== INTERNET ====="
ping -c 4 -W 2 1.1.1.1

echo
echo "===== DNS ====="
ping -c 4 -W 2 google.com

echo
echo "===== YOUTUBE ====="
curl -L -o /dev/null -s -w "HTTP: %{http_code} | Time: %{time_total}s\n" https://www.youtube.com

echo
echo "===== GOOGLEVIDEO ====="
curl -L -o /dev/null -s -w "HTTP: %{http_code} | Time: %{time_total}s\n" https://googlevideo.com

echo
echo "===== CONNECTION ====="
nmcli general status