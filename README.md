# PlantPhyloBuilder 

## How to clone this repository? 
**Install git first by running this command**:
```bash 
sudo apt install git -y
```
---
**If First Time, run this command in your desired directory in the WSL/Ubuntu command line to copy/clone this repository**:
```
git clone https://github.com/markcyril28/PlantPhyloBuilder.git
```
---
**If Second Time, run this in the directory of the PlantPhyloBuilder**:
```
git stash
```
Then, 
```
git pull
```
Or clone this repo in another directory (better and sure method):
```
git clone https://github.com/markcyril28/PlantPhyloBuilder.git
```

---

## A. Setting up the Environment and Dependencies.
### 1. Activate your WSL

- Tutorial: [How to Install WSL](https://www.youtube.com/watch?v=5RTSlby-l9w)  
**Note:** MEGA12CC is only compatible with **Ubuntu 22 or higher version**. So, install **Ubuntu 22 or higher version** instead.
- To check the version of your Ubuntu, run this command: 
```bash
lsb_release -a
```

---

### 2. Installation and Softwares to be used. 

Download megacc (MEGA12 Command-line version) from their official website:
   Choose Ubuntu/Debian, Command Line (CC), and version MEGA 12.
   Place the downloaded .deb file in ```1_CONFIG_FILES``` folder.

After placing the .deb file  in the ```1_CONFIG_FILES``` and to download all softwares and dependencies needed, run this command. 
```bash 
bash setup_script.sh
```

## C. Running Alignment and Phylogenetic Tree Analysis.  

To run the alignment and create the phylogenetic tree, run the command below. 
Choose the version you want to run. 

**For Final matk:**
```bash 
bash run_final_matk.sh 
```

**For Final 18s rRNA:**
```bash 
bash run_final_18s.sh 
```

**For Final Concatenated:**
```bash 
bash run_final_Concatenated.sh 
```

## D. After Running the Alignment and Phylogenetic Tree Generation 

- Navigate to the ```logs``` and ```2_PHYLOGENETIC_TREE_RESULTS```. 
- Copy the log files and output files accordingly to the Shared Google Drive: https://drive.google.com/drive/folders/1Ar0JSUZ1gd1uu7rrL5_Nq-E-tI0jTRci?usp=drive_link
