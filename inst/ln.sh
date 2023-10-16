
cd /etc/systemd/system
ln -s /home/anton/proj/mbharata_server/varnish/etc/systemd/system/varnish@mbharata.service

sudo systemctl enable varnish@mbharata.service




cd /etc/systemd/system
sudo ln -s /home/anton/proj/mbharata_server/cloudflare/etc/systemd/system/cloudflared.service
sudo ln -s /home/anton/proj/mbharata_server/cloudflare/etc/systemd/system/cloudflared@us.service
sudo ln -s /home/anton/proj/mbharata_server/cloudflare/etc/systemd/system/cloudflared@th.service

sudo systemctl enable cloudflared.service
sudo systemctl enable cloudflared@us.service
sudo systemctl enable cloudflared@th.service



#anton@ru1:/etc/nginx/sites-enabled$ sudo ln -s /home/anton/proj/mbharata_server/nginx/etc/nginx/mbharata.conf

sudo systemctl start varnish@mbharata.service


sudo systemctl start cloudflared.service
sudo systemctl start cloudflared@us.service
sudo systemctl start cloudflared@th.service

exit 0