# compilation et test d'un module avec yocto

Dans ce TP, vous allez tenter de développer un module pour le noyau linux de votre système yocto préparé lors du précédent TP.

Vous allez utiliser une des astuces pratiques de yocto pour compiler votre module "out of tree".

Cette solution est idéale pour faire un développement et le tester avant de proposer ce module à la communauté, ou de l'inclure dans votre noyau linux.



## Récupération du code exemple et ajout dans la meta-setr

Récupérez l'archive mydriver-mod et installez la dans votre layer **setr**. Ce répertoire doit se trouver dans un dossier recipes-kernel.

```shell
└── recipes-kernel
    └── mydriver-mod
        ├── files
        │   ├── COPYING
        │   ├── Makefile
        │   └── mydriver.c
        └── mydriver-mod_0.1.bb
```

Vous venez ainsi d'ajouter une recette à votre layer personnelle. Celle-ci est dès à présent utilisable, et va pouvoir être construite directement.

## Compilation du code exemple

Pour compiler votre module, utilisez directement la commande **bitbake**


```shell
user@hostname:$ bitbake mydriver-mod
```

Vous devriez alors obtenir un module compilé (un kernel object) du nom de votre fichier .c présent dans votre recette : mydriver.ko

Mais où se trouve ce fichier ?

Inspectez le répertoire **TP04/yocto/build-openstlinuxweston-stm32mp15-disco/tmp-glibc/work/stm32mp15_disco-ostl-linux-gnueabi/mydriver-mod/0.1/**

Si ce dossier ne contient pas votre module, alors utilisez la commande suivante, qui forcera l'installation dans ce répertoire :

```shell
user@hostname:$ bitbake -c do_install mydriver-mod
```

Notez ici que l'option do_install est passée à bitbake. 

Vous pourriez trouver utile lors de prochaines utilisations de bitbake qu'on peut lui demander de ne faire que certaines étapes, comme un do_compile ou autre.


## Test du code exemple

Une fois que vous avez obtenu votre module cross compilé. Il est temps de le tester sur la cible :

```shell
root@stm32mp15-disco:~# insmod mydriver.ko
``` 

Le log suivant devrait apparaitre : 

```shell
[ xxx.xxx] mychardev: Device initialized successfully
```

Vérifiez maintenant que votre module apparait correctement dans la liste des modules en cours d'utilisation

```shell
root@stm32mp15-disco:~# lsmod | grep mydriver
``` 

Déchargez le module pour vous assurer que l'ensemble fonctionne correctement

```shell
root@stm32mp15-disco:~# rmmod mydriver.ko
``` 


## checkpoint 
![Checkpoint](/img/validation.png) 

Faites valider que votre module (vide pour l'instant) est bien chargé et en cours d'utilisation


## Fonctions _init et _exit

Passons à présent au coeur du TP : vous allez ajouter du code au module pour que les fonctions _init et _exit fassent ce qu'elles doivent faire : créer un pseudo device en mode caractère dans lequel on pourra par la suite écrire puis lire depuis l'espace utilisateur.

Ce code étant assez complexe, il vous est fourni dans le fichier init+exit.c

Intégrez ce code dans votre module, regénérer le .ko et tester le sur votre cible

A la différence de l'étape précédente, vous devriez maintenant trouver sur votre cible, dans le répertoire **/dev** un périphérique de type caractère avec un majeur assigné automatiquement par le noyau Linux au cours de l'insertion du module.

```shell
root@stm32mp15-disco:~# ls -al /dev/mychardev
``` 

La présence de ce pseudo device indique que les étapes d'initialisation effectuée lors de l'insertion du module se sont correctement déroulées.

Vérifiez mainteant que les étapes de nettoyage prévues lors du retrait du module se font également correctement.

## checkpoint 
![Checkpoint](/img/validation.png) 

Faites valider que votre module se charge, créé le pseudo device, se décharge et supprime bien le pseudo device.

## Fonctions read et write

Vous allez enfin pouvoir donner un fonctionnel à votre module.

Celui-ci va devoir sauvegarder dans le buffer prévu à cet effet les données qui proviennent de l'espace utilisateur et qui lui sont fournies via le pseudo device créé lors de la phase précédente.

De même il aura pour fonction de restituer le contenu du buffer lorsque l'utilisateur fera une lecture du pseudo device.

NB : Lorsque vous vous placez du point de vue de l'utilisateur, la fonction de lecture du module doit correspondre à une écriture depuis l'espace noyau vers l'utilsateur et vice versa

Complètez donc les fonctions read et write du module pour atteindre le fonctionnel souhaité.

## Test du module complet

Pour tester votre module sur la cible, il vous faudra utiliser les commandes **echo** et **cat**

### ecriture vers le module

la commande **echo** a pour fonction de transmettre un flux d'octets vers un périphérique (la sortie standard par défaut). 

En lui ajoutant une redirection du type **>**, vous pouvez alors envoyer le flux dans un autre périphérique. 

Utilisez donc **echo** pour envoyer la chaîne "salut" dans votre pseudo device. Votre module devrait réagir, passer par les étapes open / write / close

```shell
[ xxx.xxx] mychardev: Device opened
[ xxx.xxx] mychardev: Written 6 bytes
[ xxx.xxx] mychardev: Device closed
```

### Lecture depuis le module

la fonction **cat** permet de transmettre un flux d'octets depuis un périphérique vers la sortie standard.

Utilisez donc **cat** pour afficher le contenu de votre pseudo device. Votre module devrait réagir, passer par les étapes open / read / close

```shell
[ xxx.xxx] mychardev: Device opened
[ xxx.xxx] mychardev: Read 6 bytes
[ xxx.xxx] mychardev: End of buffer reached
[ xxx.xxx] mychardev: Device closed
```

## checkpoint 
![Checkpoint](/img/validation.png) 

Faites valider cette dernière étape de fonctionnement.


Ici s'achève ce TP. 

Pour aller plus loin et anticiper la prochaine séance, dans l'hypothèse où vous auriez fini ce TP relativement tôt, développez une application en langage C qui va vous permettre de refaire les étapes de open / write / read / close de votre pseudo device depuis un seul binaire.

Ajoutez un appel à la fonction memset entre la fonction write et la fonction read, afin de garantir que ce que vous aurez relu depuis votre pseudo device est bien ce que le driver vous a renvoyé, et non pas ce que vous venez tout juste d'écrire.



