###Author###
#Margo Diricks (mdiricks@fz-borstel.de)

#Don´t forget to activate conda environment: conda activate plsdbapi

import os
from pathlib import Path
import sys
import getopt
from plsdbapi import query
import numpy



def myfunc(argv):
    global arg_input
    arg_input = ""
    global arg_output
    arg_output = ""
    arg_help = "{0} -i <input> -o <output>".format(argv[0])
    
    try:
        opts, args = getopt.getopt(argv[1:], "hi:o:", ["help", "input=", "output="])
    except:
        print(arg_help)
        sys.exit(2)
        
    for opt, arg in opts:
            if opt in ("-h", "--help"):
                print(arg_help)  # print the help message
                sys.exit(2)
            elif opt in ("-i", "--input"):
                arg_input = arg
            elif opt in ("-o", "--output"):
                arg_output = arg
                

    print('input:', arg_input)
    print('output:', arg_output)
    
if __name__ == "__main__":
    myfunc(sys.argv)

#print(os.path.abspath("Test/sample1.fasta"))

#arg_input="/home/mdiricks/auto/Thecus_Analysis/SeqWork/Margo/NTMseq/Test"




pathlist = Path(arg_input).rglob('*.fasta')
for path in pathlist:
     #because path is object not string
     path_in_str = str(path)
     print(path_in_str)
     



# ifile = 'GCF-022374895.2.fasta'
df = query.query_plasmid_sequence('mash_screen', ifile=path_in_str, mash_max_v=0.1, mash_min_i=0.9, mash_dist_i=True, mash_screen_w=True)
#mash_screen_wi=True: winner takes it all
#mash_min_i=0.99: minimum identity (default0.99)
#mash_max_v=0.1: max p value (default 0-1)
#mash_dist_i=True: consider individual sequences rather than fasta on its own
array = numpy.array(df)
print(df)
file = open("Test_output.txt", "w+")
content = str(array)
file.write(content)
file.close()

#mash_dist_i=True

