# PlantPhyloBuilder (This markdown file is still in Work in Progress)

---

## A. Preparation of the Environment and Dependencies.
### 1. Activate your WSL

- Tutorial: [How to Install WSL](https://www.youtube.com/watch?v=5RTSlby-l9w)  
### **BIG NOTE:** Install **Ubuntu 22** instead. 

### 2. Downloading and Initializing Conda

Reference: [Installing Miniconda on Linux](https://www.anaconda.com/docs/getting-started/miniconda/install#linux-terminal-installer)

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
source ~/.bashrc
````

---

## B. Preparation of Softwares and Website to be used. 

### MEGA Command Line Version for Phylogenetic_Analysis. 
1. Download **megacc** (MEGA12 Command-line version) from their [official website](https://www.megasoftware.net/):

   * Choose **Ubuntu/Debian**, **Command Line (CC)**, and version **MEGA 12**.
   * Place the downloaded `.deb` file in your working directory.
   * Install using:

```bash
sudo dpkg -i mega_11.0.13-1_amd64.deb
```

### Download of Softwares/Dependencies for Multiple_Sequence_Alignment.
