### A script to extract information about ligands from a pdb file

### Imports
from sys import argv
from os.path import *

### Opens the pdb file, reads the lines and put them into a list
pdb_file_name = argv[1]
pdb_file_path = str(abspath(pdb_file_name))
pdb_file = open(pdb_file_path,"r")
pdb_file_lines = pdb_file.readlines()
pdb_file.close()

### Extracts all hetero atom entries from the pdb file
list_of_heteroatoms = []
for line in pdb_file_lines:
    record_name = line[0:6]
    if record_name == "HETATM":
        list_of_heteroatoms.append(line)

###
list_of_ligand_atoms = []
for entry in list_of_heteroatoms:
    residue_name = entry[17:20]
    if residue_name == "HOH":
        pass
    else:
        list_of_ligand_atoms.append(entry)

###
list_of_unique_ligands = []
list_of_atom_ids = []
for ligand_atom in list_of_ligand_atoms:
    atom_id = (ligand_atom[21], ligand_atom[22:26])
    if atom_id in list_of_atom_ids:
        pass
    else:
        list_of_atom_ids.append(atom_id)
        list_of_unique_ligands.append(ligand_atom)

###
list_of_ligand_info = []
for ligand in list_of_unique_ligands:
    ligand_info = str(ligand[21]) + "," + str(ligand[22:26]) + "," + str(ligand[17:20]) + "\n"
    list_of_ligand_info.append(ligand_info)

###
pdb_file_dir = dirname(pdb_file_path)
print(str(pdb_file_dir))
pdb_file_stem = splitext(pdb_file_name)[0]
output_file_path = str(pdb_file_dir) + "/" + str(pdb_file_stem) + "_ligands.csv"
output_file = open(output_file_path, "w")
output_file.writelines(list_of_ligand_info)
output_file.close()
