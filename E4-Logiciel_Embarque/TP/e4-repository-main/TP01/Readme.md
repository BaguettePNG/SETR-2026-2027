# Pratique 01 : Environnement, Toolchain & Cross-Compilation

Le focus de cette première pratique est d'installer les outils de développement sur le PC

![PC de développement](../img/dev_pc.png)

En fin de séance, vous testerez la communication avec le système embarqué, ainsi qu'une première cross compilation

## Objectifs
* Installation des outils 
* Connexion du système embarqué au PC de dév
* Démarrage du système embarqué "out of the box" 
* Compilation Hello World
* Transfert application
* Test

## Installation des outils 
Le PC de développement fonctionne sous Windows. La cross-compilation se fera dans une machine virtuelle Linux. Installons le nécessaire

### Installation des outils windows 

[__VirtualBox__](https://download.virtualbox.org/virtualbox/7.1.4/VirtualBox-7.1.4-165100-Win.exe) si ce n'est pas déjà installé


[__Putty__](/tooling/putty-0-76.msi)

[__Winscp__](/tooling/WinSCP-5.19.4-Setup.exe)

[__Win32diskimager__](/tooling/win32diskimager-1.0.0-install.exe)

### Configuration de la machine virtuelle
Nommez la machine du nom de la distribution Linux à installer : __Ubuntu 22.04.5__

Installez la machine sur __C:\VirtualBox__

Dimensionnez la __RAM à la moitié de votre PC__

Créez le disque virtuel lors de l'installation

![PC de développement](/img/config_vm.png)

Dimensionnez __80 Go__ de disque dur, alloués __dynamiquement__

### Installation de la machine virtuelle
Téléchargez la version à installer : 
[__Ubuntu 22.04.5__](https://releases.ubuntu.com/jammy/ubuntu-22.04.5-desktop-amd64.iso)

Installez __Ubuntu 22.04.5__

Créez un utilisateur __swuser__ et mettre pour mot de passe __swuser__ 

Avant de redémarrer, augmenter le nombre de CPU de la machine virtuelle (à 6 voire 8, mais pas les 12 !)

/!\ Le respect de ces quelques consignes permet aux enseignants de vous venir en aide durant les TP de façon uniforme sur tous les postes !

### Configuration de Ubuntu
Configurez le proxy système
![Proxy config](/img/proxy.png)


Configurez le proxy pour apt-get
```shell
user@hostname:$ sudo nano /etc/apt/apt.conf.d/proxy.conf
```
Ajoutez les lignes suivantes 
```shell
Acquire::http::Proxy "http://cache.etu.univ-nantes.fr:3128/";
Acquire::https::Proxy "https://cache.etu.univ-nantes.fr:3128/";
```

Installez les add-ons oracle, puis redémarrez la machine virtuelle. Vous devriez maintenant pouvoir redimensionner l'écran de votre machine virtuelle.
Il peut être nécessaire d'installer certains packages pour que cette opération réussisse :

```shell
user@hostname:$ sudo apt install gcc make perl
```

Créez un dossier partagé entre windows et la machine virtuelle

Créez un répertoire linuxtmp sur votre ordinateur et le configurer dans la machine virtuelle

![shared folder](/img/shared_folder.png)


Montez le répertoire dans la machine virtuelle:
```shell
user@hostname:$ sudo mkdir /mnt/linuxtmp
user@hostname:$ sudo mount -t vboxsf linuxtmp /mnt/linuxtmp
```
## checkpoint 
![Checkpoint](/img/validation.png) 
Testez le bon fonctionnement du dossier partagé et faites le valider par Sébastien ou Laurent


### Installation des outils
Installez les outils de cross compilation ARM en EABI Hard Float
```shell
user@hostname:$ sudo apt update
user@hostname:$ sudo apt install gcc-arm-linux-gnueabihf
```
Vérifiez la version de arm-linux-gnueabihf-gcc installée :
```shell
user@hostname:$ arm-linux-gnueabihf-gcc --version
arm-linux-gnueabihf-gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0
Copyright (C) 2021 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```
Installez git, ainsi que les outils nécessaires

Pour la suite, il peut être intéressant d'installer VSCode : 
```shell
sudo snap set system proxy.http="http://cache.etu.univ-nantes.fr:3128"
$ sudo snap set system proxy.https="https://cache.etu.univ-nantes.fr:3128"
sudo snap install code --classic
```

## Connexion du système embarqué au PC de dév


![Bottom view](/img/STM32MP157F-DK2_bot.png)

1. Insérez la carte µSD fournie par ST dans le kit dans le connecteur CN15 de la carte /!\ il y a un sens à respecter, ne forcez pas !

![Top view](/img/STM32MP157F-DK2_top.png)

2. Reliez le câble réseau entre la carte réseau secondaire de votre PC et le connecteur CN8 de la carte

3. Reliez le câble USBA / microUSB entre une prise USB A de la face avant de votre PC et le connecteur CN11 de la carte

4. Démarrez putty sur votre PC et ouvrez une session sur le port série STLink en 115200bps (Vous pourrez trouvez le numéro de ce port COM dans le gestionnaire de périphériques de windows)

5. Reliez le câble USBC / USBC entre la prise USB C de la face avant de votre PC et le connecteur CN6 de la carte


## Démarrage du système embarqué "out of the box" 

### Démarrage du bootloader
![Démarrage du bootloader](/img/u-boot.png)

### Démarrage du noyau Linux
![Démarrage du noyau Linux](/img/linux.png)

### Démarrage de systemd
![Démarrage de systemd](/img/systemd.png)

Tadam ! Votre système embarqué Linux est prêt. Vous avez maintenant un système complet, fonctionnel, fourni par ST. Dans la console, vous pouvez utilisez vos premières commandes systèmes, et sur l'écran, vous pouvez utilisez les différentes démo proposées. Il nous reste à compiler un binaire et l'envoyer sur la cible, afin de valider la communication entre les 2 entités.

## Compilation Hello World
### Code en C
Sur la machine virtuelle, créez un fichier hello.c
```c
#include <stdio.h>

int main() {

        printf ("Hello, World !\n");
        return 0;
}
```
### Cross-Compilation
dans un terminal, cross-compilez le fichier pour en faire un binaire ARM _hello_
```shell 
user@hostname:$ arm-linux-gnueabihf-gcc hello.c -o hello
user@hostname:$ file hello
hello: ELF 32-bit LSB pie executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, BuildID[sha1]=c239bebb3b93a94a630fb02b9f7eb7310557f503, for GNU/Linux 3.2.0, not stripped
user@hostname:$ arm-linux-gnueabihf-size hello
   text	   data	    bss	    dec	    hex	filename
   1290	    316	      4	   1610	    64a	hello

```

## checkpoint
![Checkpoint](/img/validation.png) 

Faites valider ces étapes par Sébastien ou Laurent avant de passer à la suite


Copiez le fichier binaire vers le répertoire partagé pour le rendre accessible depuis windows

## Configuration du réseau
Sur le PC de dév, attribuez l’adresse IP 192.168.10.1 à la carte réseau de développement

Sur la cible, attribuer l’adresse IP 192.168.10.2

Vérifiez la bonne communication en testant la commande ping sur les 2 entités

### Côté Linux embarqué
```shell 
root@stm32mp1:~# ip addr add dev eth0 192.168.10.2/24 
root@stm32mp1:~# ping 192.168.10.1 
```

### Côté Windows
```shell 
ping 192.168.10.2
```

## Transfert de l'application hello

Utilisez l'application winscp pour envoyer votre fichier binaire hello depuis votre répertoire partagé windows vers le système embarqué

Vous pouvez également tester ceci en ligne de commande directement depuis le PC de dév :

```shell 
user@hostname:$ scp hello root@192.168.10.2:/home/root
```

## Test
Dans le terminal putty, éxécutez le fichier
```shell 
root@stm32mp1:~# ls -al
total 24
drwx------ 2 root root 4096 Mar 11 14:16 .
drwxr-xr-x 4 root root 4096 May 15  2022 ..
-rw-r--r-- 1 root root 7812 Mar 11 14:16 hello
root@stm32mp1:~# chmod +x hello
root@stm32mp1:~# ./hello
Hello, World !
```
## checkpoint
![Checkpoint](/img/validation.png) 
Lorsque ce point est validé par les enseignants, supprimez le fichier hello de la cible :

```shell 
root@stm32mp1:~# rm /home/root/hello
```

Eteignez le système et mettez la carte µSD dans son sachet d'origine. Cette carte doit rester intacte pour les prochaines promotions. Nous utiliserons une autre carte µSD dans le cadre des prochains TP

## Hooray
![tux](/img/tux.png) 

Vous avez atteint la fin de cette première pratique, base essentielle pour la suite des TP

## Fix

Si par erreur vous avez endommagé cette image de démo, utilisez la carte µSD d'un autre binome pour récupérer l'image originale via win32diskimager et réécrivez votre carte avec cette image originale récupérée. 

Assurez vous du bon fonctionnement de cette image. 

Merci
