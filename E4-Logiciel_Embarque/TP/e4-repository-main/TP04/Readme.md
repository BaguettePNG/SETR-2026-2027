# Génération d'une image pour STM32MP157F-DK2 avec yocto


## Récupération des recettes

En utilisant le logiciel **repo** vous allez télécharger les premiers éléments de yocto, nécessaires au build de l'image pour la carte d'évaluation STM32MP157F-DK2

Pour information, la base de ce tuto se trouve ici : https://wiki.stmicroelectronics.cn/stm32mpu/wiki/STM32MPU_Distribution_Package 

Vous trouverez les commandes les plus utiles dans la suite de ce document, mais vous pouvez librement lire le tuto de ST au préalable

```shell
user@hostname:$ mkdir -p TP04/yocto
user@hostname:$ cd TP04/yocto
user@hostname:$ repo init -u https://github.com/STMicroelectronics/oe-manifest.git -b refs/tags/openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06
user@hostname:$ repo sync
```

## Configuration de l'image à construire
Configurez l'image yocto, en sourcant l'environnement fourni par ST

```shell
user@hostname:$ DISTRO=openstlinux-weston MACHINE=stm32mp15-disco IMAGE=st-image-core source layers/meta-st/scripts/envsetup.sh
```

## Gestion des sstate-cache et downloads partagés

Le temps de build de yocto est assez long, cela m'a pris plus de 4h pour avoir un build complet de l'image minimale que vous vous apprêtez à générer.

Pour autant, Yocto utilise un système de cache, qui une fois partagé permet de réduire énormément le temps d'un premier build sur une nouvelle machine.

2 répertoires sont importants pour celà : 
- **sstate-cache** : le répertoire dans lequel yocto sauvegarde les **shared states** et donc les états des différentes recettes
- **downloads** : le repertoire dans lequel yocto sauvegarde tous les paquets téléchargés depuis les SRC_URI des recettes.

En utilisant les dossiers que j'ai peuplé lors de mon build, et que je vous partage, votre premier build devrait prendre une vingtaine de minutes seulement !

### option 1 : depuis un serveur WEB
Modifiez le fichier TP04/yocto/build-openstlinuxweston-stm32mp15-disco/conf/site.conf pour lier votre configuration à mes répertoires. Ajoutez à la fin du fichier les lignes suivantes :
```text
# Attempt to get source from this mirror after looking in DL_DIR, but before SRC_URI
SOURCE_MIRROR_URL ?= "http://polytech.casaloka.fr/bitbake.downloads"
INHERIT += "own-mirrors"
 
 
SSTATE_MIRRORS ?= "file://.* http://polytech.casaloka.fr/bitbake.sstate/PATH;downloadfilename=PATH"
```

Pour vérifier que bitbake voit bien le cache, lancez la commande suivante

```shell
user@hostname:$ bitbake st-image-core --setscene-only
```
Il ne devrait pas manquer plus de 100 miroirs. Si il en manque plus que cela, relancez cette commande pour forcer le rafraichissement des shared states

#### exemple KO
```shell
Sstate summary: Wanted 3811 Local 0 Mirrors 2697 Missed 1114 Current 0 (70% match, 0% complete)
```
Notez ici que le nombre de Missed (1114) est très élevé, relancez la commande

#### exemple OK
```shell
Sstate summary: Wanted 461 Local 0 Mirrors 335 Missed 126 Current 3350 (72% match, 96% complete)
```
Il ne manque ici plus que 126 miroirs, vous pouvez à présent lancer le build

### option 2 : en local
Décompressez localement l'archive yocto fournie ici : http://polytech.casaloka.fr/yocto.7z

Modifiez le fichier **TP04/yocto/build-openstlinuxweston-stm32mp15-disco/conf/local.conf** pour lier votre configuration à mes répertoires. Ajoutez à la fin du fichier les lignes suivantes :

```text
SSTATE_DIR = "${TOPDIR}/bitbake.sstate"
DL_DIR = "${TOPDIR}/bitbake.downloads"
```

## Génération du système
LAncez la génération du système à l'aide de l'outil bitbake. il suffit de lui indiquer le nom de l'image cible à construire.

l'outil va alors faire les différentes étapes de construction :
* téléchargement des composants (do_fetch)
* application des patchs (do_patch)
* configuration (do_configure)
* compilation (do_compile)
* installation (do_install)
pour ne citer que les plus importantes !

```shell
user@hostname:$ bitbake st-image-core
```

Validez les conditions en sélectionnant le bouton **ACCEPT EULA** lorsque la fenêtre se présente à vous

Accordez vous un peu de temps pour regarder ce que la sortie du builder produit, vous devriez voir plusieurs threads en parallèle réaliser ces différentes tâches.

## test du système

Lorsque le build est terminé, vous aurez dans le répertoire **build-openstlinuxweston-stm32mp15-disco/tmp-glibc/deploy/images/stm32mp15-disco** tous les éléments constitutifs de votre image à écrire sur carte SD. N

éanmoins, il va falloir utiliser un script pour assembler tous ces élements en un seul fichier monolithique à écrire sur la sarte SD. En effet, ST proposer des outils pour écrire chacun de ces éléments de façon séparée, mais nous n'utiliserons pas ces outils ici...

```shell
user@hostname:$ cd build-openstlinuxweston-stm32mp15-disco/tmp-glibc/deploy/images/stm32mp15-disco/scripts
user@hostname:$ ./create_sdcard_from_flashlayout.sh ../flashlayout_st-image-core/opteemin/FlashLayout_sdcard_stm32mp157f-dk2-opteemin.tsv
```

Utilisez le fichier ainsi généré : **FlashLayout_sdcard_stm32mp157f-dk2-opteemin.raw** et écrivez le sur votre carte µSD depuis votre windows pour tester cette image fraichement générée.

***En aparté***

Pour les utilisateurs Linux natifs, voici les commandes pour écrire la carte µSD

```shell
user@hostname:$ sudo dd if=FlashLayout_sdcard_stm32mp157f-dk2-opteemin.raw of=/dev/mmcblk0 bs=8M conv=fdatasync status=progress
user@hostname:$ sudo sgdisk /dev/mmcblk0 -p
```

## test du système
Lors du premier démarrage du système, vous allez voir que le boot est long. Ceci est dû au fait que ST a implémenté un système de "resizing" des partitions, afin d'occuper tout l'espace disponible sur la carte µSD, et va donc étendre les différentes partitions de l'image au plus large possible.

Lorsque le boot est terminé, vous avez accès au prompt. 

Profitez en pour vérifier la version du noyau Linux en cours d'utilisation. 

## test des LEDs et des boutons

En appuyant sur le bouton USER 2, vous devriez voir la LED rouge s'allumée, et en appuyant sur USER 1, c'est la LED verte qui devrait s'allumer

Ceci est lié à l'implémentation hard faite par ST sur ces 2 GPIO PA13 et PA14 qui sont à la fois sorties pour les LEDS et entrées pour les boutons.

source : https://wiki.stmicroelectronics.cn/stm32mpu/wiki/STM32MP157x-DKx_-_hardware_description#User_buttons_and_LEDs



Utilisez maintenant 2 scripts fournis par ST pour tester les leds et les boutons

```shell
root@stm32mp1:~# cd /usr/local/Linux-A7-examples/GPIO/leds/
root@stm32mp1:~# ./toggle_led.sh
```
Ce premier script fait clignoter la LED rouge

```shell
root@stm32mp1:~# cd /usr/local/Linux-A7-examples/GPIO/buttons
root@stm32mp1:~# ./button_gpio_exti.sh
```
Ce second script fait allumer ou éteindre la led verte, selon que le bouton USER 1 est appuyé ou relâché.

Malheureusement, ces scripts semblent ne pas fonctionner comme espéré.

La raison pourrait être que ces scripts ont été écrits pour une version plus ancienne de la librairie GPIOD. 

Dans votre distribution yocto, basée sur la LTS scarthgap, la libgpiod est passée en V2.x ou supérieure. Une rupture de compatibilité a été introduite entre les versions 1 et 2. 

De fait les utilitaires qui s'appuient sur cette librairie (gpioset, gpioget et gpiomon entre autres) n'ont plus la même API.

Vous allez donc devoir modifier ces scripts en utilisant les outils yocto.

## utilisation de la nouvelle API

commencez par tester ces différentes commandes :
```shell
# Allumage LED rouge
root@stm32mp1:~# gpioset -t0 --by-name PA13=0
# Extinction LED rouge
root@stm32mp1:~# gpioset -t0 --by-name PA13=1
# Allumage LED verte
root@stm32mp1:~# gpioset -t0 --by-name PA14=0
# Extinction LED verte
root@stm32mp1:~# gpioset -t0 --by-name PA14=1
```
Si le fonctionnement est correct, passez à la lecture des boutons poussoirs

```shell
# Lecture bouton USER 2
root@stm32mp1:~# gpioget --numeric --by-name PA13

# Lecture bouton USER 1
root@stm32mp1:~# gpioget --numeric --by-name PA14
```
Si cela fonctionne pour la lecture d'un état haut, puis d'un état bas, testez maintenant le monitoring (action bloquante) des boutons

```shell
root@stm32mp1:~# gpiomon -n 1 --by-name PA13
```
En utilisant l'aide de cette fonction, voyez comment faire une detection de front descendant, et comment rendre ce démon silencieux.

Une fois tous ces essais terminés, vous devriez avoir les idées un peu plus claires sur la correction à apporter aux scripts de ST pour les rendre fonctionnels.

Au passage, nous vous demandons de modifier un peu le script de gestion du bouton pour que la surveillance se fasse sur le bouton USER 2 et allume la LED verte. Ceci afin de ne plus être dépendant de l'implémentation hardware des LEDs / boutons qui veut que si vous appuyez sur le bouton USER 1, la LED verte s'allume déja

N'implémentez rien pour le moment sur la cible, vous allez avoir l'occasion de faire ces modifications sur votre PC de développement et de tester ces modifications via le déploiement sur cible offert par yocto


## Correction de la recette et test sur cible
La recette qui apporte ces scripts se trouve dans la layer meta-st (fort logiquement, s'agissant de scripts écrits par ST pour les cartes d'évaluations ST !)

Vous allez donc utiliser devtool, un des utilitaires de yocto pour gérer des modifications de recette, les tester, et produire les éléments d'intégration à vos recettes et layers.

Commencez par placer la recette en modification
```shell
user@hostname:$ devtool modify linux-examples-stm32mp1
```

Procédez maintenant aux corrections en éditant les 2 scripts non fonctionnels
```shell
user@hostname:$ cd TP04/yocto/build-openstlinuxweston-stm32mp15-disco/workspace/sources/linux-examples-stm32mp1/
user@hostname:$ code .
```
Souvenez-vous, lors du premier TP vous avez installé visual studio code. Cet éditeur de texte va vous permettre d'éditer de façon structurée les scripts.

```shell
user@hostname:$ devtool build linux-examples-stm32mp1
```

une erreur se produit dans le do_install, n'en tenez pas compte.

Passez au déploiement sur cible pour tester vos modifications.

```shell
user@hostname:$ devtool deploy-target linux-examples-stm32mp1 root@192.168.10.2 -s
```

## checkpoint 
![Checkpoint](/img/validation.png) 
Il est temps de faire valider vos modifications avant de passer à la suite

## Validation des modifications dans devtool

Lorsque vos modifications sont faites, il va falloir propager ces changements. L'outil devtool, en plus de déployer le code lié à la recette que vous modifiez, initialise un repository git local, qui va vous permettre de suivre les corrections et de générer un ou des patchs pour la recette en cours de modification.

```shell
user@hostname:$ git diff
user@hostname:$ git add GPIO/buttons/button_gpio_exti.sh GPIO/leds/toggle_led.sh 
```
Lors du commit, ajoutez un message explicite sur les modifications apportées, car devtool se sert de ce message pour générer le nom du fichier de patch

```shell
user@hostname:$ git commit -m "fix API for gpio"
```

Ces commandes git ont eu pour effet de "pousser" sur le repository local créé par devtool vos modifications. Il va maintenant falloir les tester


## creation d'une nouvelle layer

Il est maintenant temps d'utiliser un autre outil de yocto, qui permet d'accompagner les développeurs dans la création d'une layer.
En effet, il n'est pas recommandé de modifier directement le code fourni par ST dans sa layer, ceci pour une raison évidente de reproductibilité et d'indépendance aux modifications faites par la suite dans cette layer.

```shell
user@hostname:$ cd TP04/yocto/
user@hostname:$ bitbake-layers create-layer --priority 7 layers/meta-setr
user@hostname:$ cd yocto/layers
user@hostname:$ tree -L 1 .
```

Vous devriez avoir une arboresence de ce type

```shell
.
├── meta-openembedded
├── meta-setr
├── meta-st
└── openembedded-core

4 directories, 0 files
```
Inspectez maintenant la layer fraichement créée

```shell
user@hostname:$ tree -L 1 meta-setr/
```

```shell
meta-setr/
├── conf
├── COPYING.MIT
├── README
└── recipes-example

2 directories, 2 files
```

Il est recommandé de modifier le README pour expliquer ici à quoi va servir votre layer. Vous pouvez y indiquer que votre layer servira pour les prochains TP autour de yocto


## Ajout de la nouvelle layer

La layer que vous avez créée est pour le moment inconnue de bitbake, vérifiez ceci 
```shell
user@hostname:$ bitbake-layers show-layers
```

```shell
layer                 path                                                                    priority
========================================================================================================
meta-python           TP04/yocto/layers/meta-openembedded/meta-python  5
openembedded-layer    TP04/yocto/layers/meta-openembedded/meta-oe  5
gnome-layer           TP04/yocto/layers/meta-openembedded/meta-gnome  5
multimedia-layer      TP04/yocto/layers/meta-openembedded/meta-multimedia  5
networking-layer      TP04/yocto/layers/meta-openembedded/meta-networking  5
webserver             TP04/yocto/layers/meta-openembedded/meta-webserver  5
stm-st-stm32mp        TP04/yocto/layers/meta-st/meta-st-stm32mp  6
st-openstlinux        TP04/yocto/layers/meta-st/meta-st-openstlinux  5
core                  TP04/yocto/layers/openembedded-core/meta  5
```

On constate ici que la layer n'est pas prise en compte. Il faut donc maintenant indiquer à bitbake que cette layer est à considérer

```shell

user@hostname:$ bitbake-layers add-layer ../layers/meta-setr
user@hostname:$ bitbake-layers show-layers
```


```shell
layer                 path                                                                    priority
========================================================================================================
meta-python           TP04/yocto/layers/meta-openembedded/meta-python  5
openembedded-layer    TP04/yocto/layers/meta-openembedded/meta-oe  5
gnome-layer           TP04/yocto/layers/meta-openembedded/meta-gnome  5
multimedia-layer      TP04/yocto/layers/meta-openembedded/meta-multimedia  5
networking-layer      TP04/yocto/layers/meta-openembedded/meta-networking  5
webserver             TP04/yocto/layers/meta-openembedded/meta-webserver  5
stm-st-stm32mp        TP04/yocto/layers/meta-st/meta-st-stm32mp  6
st-openstlinux        TP04/yocto/layers/meta-st/meta-st-openstlinux  5
core                  TP04/yocto/layers/openembedded-core/meta  5
meta-setr             TP04/yocto/layers/meta-setr  7
```
Utilisez à nouveau devtool pour mettre à jour la recette précedemment modifiée, mais en lui indiquant que ces modifications sont à mettre dans votre layer setr

```shell
user@hostname:$ devtool update-recipe -a layers/meta-setr/ linux-examples-stm32mp1 
```

Vous noterez qu'un sous-répertoire a été ajouté dans votre layer : **meta-setr/recipes-extended/linux-examples/** Ce dossier contient un fichier .bbappend pour modifier la recette initiale et un fichier patch pour modifier les scripts.


## checkpoint 
![Checkpoint](/img/validation.png) 
Avant de passer au test sur cible, faites vérifier à Laurent ou Sébastien que tous les éléments sont bien en place pour la suite des choses


## fermeture de devtool
Toutes vos modifications étant maintenant disponibles sous forme de patchs dans votre layer setr, vous pouvez remettre la recette hors de modification.

```shell
user@hostname:$ devtool reset linux-examples-stm32mp1 
```


## recompilation de votre image complète
Relancez bitbake pour générer une nouvelle fois l'image

## checkpoint 
![Checkpoint](/img/validation.png) 
Vous pouvez maintenant nous faire voir les 2 scripts corrigés sur votre cible, et nous moontrer qu'ils fonctionnet correctement

Félicitations, vous venez d'utiliser yocto pour la première fois, en réalisant ces quelques actions :
* Générer un système minimal avec **bitbake**
* Corriger une recette en la testant sur cible avec **devtool**
* Créer et peupler une layer avec **bitbake-layer** et **devtool**


