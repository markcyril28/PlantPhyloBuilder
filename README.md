# PlantPhyloBuilder 

## How to clone this repository? 
Install git first by running this command: 
```bash 
sudo apt install git -y
```

If First Time, run this command in your desired directory in the wsl/ubuntu command line to copy/clone the repository: 
```
git clone https://github.com/markcyril28/PlantPhyloBuilder.git
```

If Second Time, run this in the directory of the PlantPhyloBuilder
```
git pull
```
or clone the repo in another directory:
```
git clone https://github.com/markcyril28/PlantPhyloBuilder.git
```

---

## A. Preparation of the Environment and Dependencies.
### 1. Activate your WSL

- Tutorial: [How to Install WSL](https://www.youtube.com/watch?v=5RTSlby-l9w)  
### **Big Note:** MEGA12CC is only compatible with **Ubuntu 22 or higher version**. So, install **Ubuntu 22 or higher version** instead.
- To check the version of your Ubuntu, run this command: 
```bash
lsb_release -a
```

---

## B. Preparation of Softwares and Website to be used. 

Download megacc (MEGA12 Command-line version) from their official website:
   Choose Ubuntu/Debian, Command Line (CC), and version MEGA 12.
   Place the downloaded .deb file in ```1_CONFIG_FILES```.

To download all softwares and dependencies needed, run this command. 
```bash 
bash setup_script.sh
```

## C. Running Alignment and Phylogenetic Tree Analysis. 

To run the alignment and create the phylogenetic tree, run the command below. 
Choose the version you want to run. 

**For 64 genes version:**
```bash 
bash generate_Alignment_and_Phylo_64_genes_version.sh 
```

**For 21 lifted genes version:**
```bash 
bash generate_Alignment_and_Phylo_21_lifted_genes_version.sh 
```

**For Curated 21 genes version:**
```bash 
bash generate_Alignment_and_Phylo_curated_21_genes_version.sh 
```

## D. After Running the Alignment and Phylogenetic Tree Generation 

- Navigate to the ```2_PHYLOGENETIC_TREE_RESULTS```
- Copy the output files accordingly to the Shared Google Drive: https://drive.google.com/drive/folders/1Ar0JSUZ1gd1uu7rrL5_Nq-E-tI0jTRci?usp=drive_link

## E. Final Run (64 genes version)

**For 18s:**
```bash 
bash generate_Alignment_and_Phylo_64_genes_version_18s.sh 
```

**For matK:**
```bash 
bash generate_Alignment_and_Phylo_64_genes_version_matk.sh 
```

**For concatenated:**
```bash 
bash generate_Alignment_and_Phylo_64_genes_version_concatenated.sh 
```