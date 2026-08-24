import Bio.PDB
import numpy
import pylab

#Imports
from sys import argv
from os.path import *

#Arguments for the command
pdb_code = argv[1]
pdb_filename = argv[2]
chain_monomerA = argv[3]
chain_monomerB = argv[4]

def calc_residue_dist(residue_one, residue_two) :
    """Returns the C-alpha distance between two residues"""
    diff_vector  = residue_one["CA"].coord - residue_two["CA"].coord
    return numpy.sqrt(numpy.sum(diff_vector * diff_vector))

def calc_dist_matrix(chain_one, chain_two) :
    """Returns a matrix of C-alpha distances between two chains"""
    answer = numpy.zeros((len(chain_one), len(chain_two)), numpy.float)
    for row, residue_one in enumerate(chain_one) :
        for col, residue_two in enumerate(chain_two) :
            answer[row, col] = calc_residue_dist(residue_one, residue_two)
    return answer

structure = Bio.PDB.PDBParser().get_structure(pdb_code, pdb_filename)
model = structure[0]
dist_matrix = calc_dist_matrix(model[chain_monomerA], model[chain_monomerB])
contact_map = dist_matrix < 36

print ("Minimum distance", numpy.min(dist_matrix))
print ("Maximum distance", numpy.max(dist_matrix))


#Distance Matrix
pylab.matshow(numpy.transpose(dist_matrix))
pylab.colorbar()
pylab.show()

#Contact Map
#pylab.autumn()
#pylab.imshow(numpy.transpose(contact_map))
#pylab.show()