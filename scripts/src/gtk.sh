mkdir -p $HOME/.icons
cd /tmp
git clone https://github.com/vinceliuice/Qogir-icon-theme
cd Qogir-icon-theme
chmod +x install.sh
./install.sh

mkdir -p $HOME/.themes
cd $HOME/.themes
git clone https://github.com/EliverLara/Space.git
