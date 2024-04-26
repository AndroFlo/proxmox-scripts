#!/bin/bash

# Vérifier que le script est exécuté en tant que root
if [ "$(id -u)" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que root" >&2
  exit 1
fi

# Fonction pour demander une valeur avec une invite
ask_value() {
    local prompt="$1"
    local value
    read -rp "$prompt: " value
    echo "$value"
}

# Demander les informations nécessaires
user=$(ask_value "Nom de l'utilisateur")
group=$(ask_value "Nom du groupe")
partage=$(ask_value "Nom du partage")
path=$(ask_value "Chemin du partage")

# Mettre à jour les paquets
apt-get update

# Installer Samba
apt-get install -y samba

# Vérifier le statut de smbd
systemctl status smbd

# Activer smbd
systemctl enable smbd

# Ajouter le contenu dans smb.conf
echo "[$partage]
   comment = Partage de données
   path = $path
   guest ok = no
   read only = no
   browseable = yes
   valid users = @$group" >> /etc/samba/smb.conf

# Redémarrer smbd
systemctl restart smbd

# Créer un nouvel utilisateur
adduser $user

# Définir le mot de passe Samba pour l'utilisateur
smbpasswd -a $user

# Créer un nouveau groupe
groupadd $group

# Ajouter l'utilisateur au groupe partage
gpasswd -a $user $partage

# Créer le répertoire de partage
mkdir $path

# Définir le groupe propriétaire du répertoire de partage
chgrp -R $partage $path

# Définir les permissions du répertoire de partage
chmod -R g+rw $path

echo "Configuration terminée."
