# How to crack MestReNova 12 for Ubuntu

Unfortunately, the Mnova binary file for Linux does not posses an explicit pattern to be patched just like the one for Windows or MacOS. Therefore, the modified binary file is distributed here as an alternative way. Note that this cracked binary file was modified based on the **12.0.4 version for Ubuntu 18.04**, so this trick *may not* work for other versions.

- Firstly, download .deb installer from the [Mnova website](https://mestrelab.com/downloads/mnova/linux/Ubuntu/18.04/mestrenova_12.0.4-22023_amd64.deb) and then run it;

- Download the [cracked package](/MRN_for_Ubuntu/crack.tgz). In the same folder where you downloaded the package, run Terminal;

- Type in the following commands and then execute. **If permission denied, you should run the command line with `sudo` at the beginning**;
  
```bash
MRNDIR=$(dirname $(readlink -f `which MestReNova`))/../lib
mv $MRNDIR/MestReNova $MRNDIR/MestReNova.bak
tar -xzvf crack.tgz -C $MRNDIR
```

- OK.
