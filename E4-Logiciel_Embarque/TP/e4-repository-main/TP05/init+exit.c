// Fonction d'initialisation du module
static int __init my_init(void) {
    int ret;

    // Allocation d'un major/minor dynamique
    ret = alloc_chrdev_region(&dev_num, 0, 1, DEVICE_NAME);
    if (ret) {
        pr_err("mychardev: Failed to allocate device number\n");
        return ret;
    }

    // Initialisation du cdev
    cdev_init(&my_cdev, &my_fops);
    my_cdev.owner = THIS_MODULE;

    // Ajout du cdev au noyau
    ret = cdev_add(&my_cdev, dev_num, 1);
    if (ret) {
        pr_err("mychardev: Failed to add cdev\n");
        unregister_chrdev_region(dev_num, 1);
        return ret;
    }

    // Création de la classe
    my_class = class_create(DEVICE_NAME);
    if (IS_ERR(my_class)) {
        pr_err("mychardev: Failed to create class\n");
        cdev_del(&my_cdev);
        unregister_chrdev_region(dev_num, 1);
        return PTR_ERR(my_class);
    }

    // Création du device node /dev/mychardev
    if (!device_create(my_class, NULL, dev_num, NULL, DEVICE_NAME)) {
        pr_err("mychardev: Failed to create device\n");
        class_destroy(my_class);
        cdev_del(&my_cdev);
        unregister_chrdev_region(dev_num, 1);
        return -1;
    }

    pr_info("mychardev: Device initialized successfully\n");
    return 0;
}

// Fonction de nettoyage du module
static void __exit my_exit(void) {
    device_destroy(my_class, dev_num);
    class_destroy(my_class);
    cdev_del(&my_cdev);
    unregister_chrdev_region(dev_num, 1);
    pr_info("mychardev: Device unregistered\n");
}
