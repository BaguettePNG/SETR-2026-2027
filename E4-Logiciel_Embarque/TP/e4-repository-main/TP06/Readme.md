# Utilisation de Systemd

Dans ce TP, vous allez tenter de développer un script shell qui va utiliser votre module du TP précédent, puis qui sera lancé par un service.


## Ecriture du script et test

Créez un script shell **test-driver.sh** qui va tester la présence de votre module, l'insérer si ce n'est pas déja fait, puis appeler les commandes echo puis cat sur le device que vous avez créé au TP précédent

Envoyez ce script sur votre cible (ou mettez le au point directement sur votre cible).

NB : si vous ne vous sentez pas à l'aise avec ce script, vous pouvez recourir à l'IA pour la génération du script.  Ce n'est pas le point clé du TP. 

Un indice tout de même : le module à insérer se trouvera ici : /usr/lib/modules/6.6.48/updates/mydriver.ko

## checkpoint 
![Checkpoint](/img/validation.png) 

Faites valider ce point

## Intégration du script dans une recette

Lorsque c'est fait, ajoutez le dans votre layer **meta-setr** en créant une nouvelle recette avec les outils yocto

```shell
user@hostname:$ cd TP04/yocto/layers
user@hostname:$ mkdir -p meta-setr/recipes-test/driver-test/files
user@hostname:$ cp <path-to-your>test-driver.sh meta-setr/recipes-test/driver-test/files/.
user@hostname:$ code meta-setr/recipes-test/driver-test/driver-test_1.0.bb
```

```text
SUMMARY = "Driver Test Script and Service"
DESCRIPTION = "Simple script to test driver functionalities"
LICENSE = "CLOSED"

SRC_URI = "file://test-driver.sh"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/test-driver.sh ${D}${bindir}/test-driver.sh
}
```

Une fois les fichiers mis en place, vous devriez avoir une arborescence de votre recette de test qui ressemble à ceci

```shell
meta-setr
...
└── recipes-test
    └── driver-test
        ├── driver-test_1.0.bb
        └── files
            └── test-driver.sh

```

Vous venez ainsi d'ajouter une recette à votre layer personnelle. 

Celle-ci doit être inclue à votre image. Mais commençons par la compiler pour vérifier que tout se passe bien.

## Construction de la recette

Pour construire votre recette, utilisez directement la commande **bitbake**


```shell
user@hostname:$ bitbake driver-test 
user@hostname:$ bitbake driver-test -c do_install
```

Vous devriez alors obtenir un script test-driver.sh.

Inspectez le répertoire **TP04/yocto/build-openstlinuxweston-stm32mp15-disco/tmp-glibc/work/cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi/driver-test/1.0/**


## Ajout d'un fichier unité pour systemd

Vous allez maintenant créez le fichier **.service** qui sera responsable de l'utilisation de votre script

```shell
user@hostname:$ code meta-setr/recipes-test/driver-test/files/test-driver.service
```

Ajoutez le code suivant dans ce fichier

```text
[Unit]
Description=Driver Test Script Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/test-driver.sh
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
```

Ajoutez ce fichier à votre recette, pour qu'il soit installé convenablement

```shell
user@hostname:$ code meta-setr/recipes-test/driver-test/driver-test_1.0.bb
```

Ajoutez votre fichier sur la ligne SRC_URI.

Complétez la section do_install pour que votre service soit installé au bon endroit pour être pris en compte par systemd. Faites enfin hériter votre recette du package systemd et déclarez votre service auprès de systemd

```text
do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/test-driver.service ${D}${systemd_system_unitdir}/test-driver.service
}

SYSTEMD_SERVICE:${PN} = "test-driver.service"
inherit systemd
```

Reconstruisez votre recette pour tester que tout se passe bien.

## checkpoint 
![Checkpoint](/img/validation.png) 

Faites valider que votre recette construite présente bien les fichiers attendus dans le répertoire de travail de yocto

## construction de l'image complète

Votre recette étant valide, il faut maintenant l'ajouter à votre image.

Pour celà, il faut créer un fichier bbappend sur l'image que vous construisez, et lui signifier d'ajouter votre recette à l'image

```shell
user@hostname:$ cd TP04/yocto/layers
user@hostname:$ mkdir -p meta-setr/recipes-core/images
user@hostname:$ code meta-setr/recipes-core/images/st-image-core.bbappend
```

Ajoutez la ligne suivante dans ce fichier


```text
IMAGE_INSTALL:append= " driver-test mydriver-mod"
```

Notez qu'ici, nous ajoutons 2 recettes à l'image : votre recette de test fraichement créée, mais également la recette de votre module "out of tree" du TP précédent. La boucle est ainsi bouclée...

Vous allez pouvoir reconstruire l'image complète, la flasher et la tester sur votre cible.

## Test de l'image

Une fois l'image démarrée, vous devriez trouver 
- le script test-driver.sh dans /usr/bin
- le service test-driver.service dans /usr/lib/systemd/system
- le kernel module mydriver.ko dans /usr/lib/modules/6.6.48/updates

Notez que concernant le service et le script, c'est précisément ce que vous avez demandé dans votre recette dans la section do_install

Commencez par voir si votre service s'est bien lancé au démarrage

```shell
root@stm32mp1:~# systemctl status test-driver.service
root@stm32mp1:~# journalctl -u test-driver.service
```

## checkpoint 
![Checkpoint](/img/validation.png) 

Faites valider ce point


Si vous avez le temps, tentez de modifier votre script pour qu'il ne charge plus le module, mais que soit fait par le service dans une étape de PreExecStart (voir la doc de systemd pour plus d'informations)
