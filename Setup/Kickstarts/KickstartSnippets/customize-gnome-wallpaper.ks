## Customize Gnome Wallpaper for FC42
mkdir -p /usr/share/backgrounds/f40/default/
cd /usr/share/backgrounds/f40/default/
rm *.png
wget http://localhost/files/f38-01-night.png
wget http://localhost/files/f38-01-day.png
cd /usr/share/backgrounds/gnome
mv f38-01-night.png f42-night.png
mv f38-01-day.png f42-day.png
mv /usr/share/backgrounds/gnome/adwaita-l.jpg /usr/share/backgrounds/gnome/adwaita-l.orig
mv /usr/share/backgrounds/gnome/adwaita-d.jpg /usr/share/backgrounds/gnome/adwaita-d.orig
cp f42-day.png /usr/share/backgrounds/gnome/adwaita-l.jpg
cp f42-night.png /usr/share/backgrounds/gnome/adwaita-d.jpg
