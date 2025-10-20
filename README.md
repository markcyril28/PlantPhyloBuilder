# PlantBarcodeScanner_and_PhytoReceiptMaker (This markdown file is work in progress)

---

## A. Preparation of the Environment and Dependencies.
### 1. Activate your WSL

- Tutorial: [How to Install WSL](https://www.youtube.com/watch?v=5RTSlby-l9w)  
  **Note:** Install **Ubuntu 22** instead of the version shown.

### 2. Downloading and Initializing Conda

Reference: [Installing Miniconda on Linux](https://www.anaconda.com/docs/getting-started/miniconda/install#linux-terminal-installer)

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
source ~/.bashrc
````

### 3. Creating a Conda Environment: Basic Cheatsheet

```bash
conda create -n PlantPhyloBuilder_ENV
conda activate PlantPhyloBuilder_ENV
conda deactivate
```

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

### Clustal Omega for 04_Multiple_Sequence_Alignment.

#### Command-line version 
1. Open WSL. Activate your conda environment for your analysis.  
2. Install Clustal Omega (clustalo) from conda using the script below while inside the conda environment.

```bash
conda install clustalo
```
#### Website version. 
1. Go to their [website](https://www.ebi.ac.uk/jdispatcher/msa/clustalo). 
2. Input your sequence. 
3. Wait for the result. 
