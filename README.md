
# PlantBarcodeScanner_and_PhytoReceiptMaker

Post-processing pipeline for plant barcoding genes such as *ITS*, *matK*, and *rbcL*.

---

## 1. Activate your WSL

- Tutorial: [How to Install WSL](https://www.youtube.com/watch?v=5RTSlby-l9w)  
  **Note:** Install **Ubuntu 22** instead of the version shown.

---

## 2. Downloading and Initializing Conda

Reference: [Installing Miniconda on Linux](https://www.anaconda.com/docs/getting-started/miniconda/install#linux-terminal-installer)

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
source ~/.bashrc
````

### Creating a Conda Environment: Basic Cheatsheet

```bash
conda create -n PlantBarcodeScanner_env
conda activate PlantBarcodeScanner_env
conda deactivate
```

---

## 3. Preparation of Some Dependencies

1. Download **megacc** (MEGA Command-line version):

   * Choose **Ubuntu/Debian**, **Command Line (CC)**, and version **MEGA 11**.
   * Place the downloaded `.deb` file in your working directory.

2. Install using:

```bash
sudo dpkg -i mega_11.0.13-1_amd64.deb
```

2. Install Clustal Omega (clustalo) from conda using the script below while inside the conda environment.

```bash
conda install clustalo
```

