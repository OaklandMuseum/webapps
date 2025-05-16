# this version of the 'convert' script for DSS 2022
# expects to concatenate a few columns in the input
# thereby reduce the number of columns in the output
# see create-nextview.sql

import csv
import sys
import re

# map columns in input (4solr file) to columns in output file
# concatenating a few as needed
concatenate_cols = [
    [0],
    [1],
    [2],
    [3, 4],
    [6],
    [8],
    [10, 20],         # person      6
    [11, 5, 15, 19],  # place       7
    [13, 14],         # maker = org + person
    [9, 21],          # org         9
    [25],
    [12],
    [15],
    [16],
    [17],
    [18],
    [22],
    [23],             # 17
    [24],
    [7]               # 19
]

# this is how the input columns are mapped to output columns
"""
     0	objectname_s
     1	objectnumber_s
     2	dhname_s
     3	physicaldescription_s,contentdescription_s
     4	ipaudit_s
     5	assocculturalcontext_ss
     6	assocperson_ss,contentpersons_ss
     7	assocplace_ss,fieldcollectionplace_s,objectproductionplace_ss,contentplaces_ss
     8	objectproductionorganization_ss,objectproductionperson_ss
     9	assocorganization_ss,contentorganizations_ss
    10	objectproductiondate_ss
    11	material_ss
    12	objectproductionplace_ss
    13	title_ss
    14	technique_ss
    15	contentconcepts_ss
    16	exhibitionhistories_ss
    17	dimensionsummary_s
    18	creditline_ss
    19	moddate_dt
"""

# list of single-valued fields in the output, used so we don't encapsulate them
single_valued = [1, 2, 3, 4, 10, 13, 17, 19]

txt_file = sys.argv[1]
csv_file = sys.argv[2]

def encapsulate(row, cols):
    # encapsulate items with commas in double quotes, double the double quotes
    for c in cols:
        t = row[c].split('|')
        z = []
        for x in t:
            if ',' in x:
                x = f'"{x}"'
            z.append(x)
        row[c] = ','.join(z)

with open(txt_file, "r") as in_text:
    in_reader = csv.reader(in_text, delimiter='\t')
    with open(csv_file, "w") as out_csv:
        out_writer = csv.writer(out_csv, escapechar='\\', quoting=csv.QUOTE_MINIMAL, quotechar='"', delimiter='\t')
        for row in in_reader:
            output_row = []
            for i, cols in enumerate(concatenate_cols):
                # truncate exhibition histories on semicolon
                if cols[0] == 22:
                    row[cols[0]] = row[cols[0]].split(';')[0]
                if i in single_valued:
                    output_row.append(' '.join([row[c] for c in cols if row[c] != '']))
                else:
                    encapsulate(row, cols)
                    output_row.append(','.join([row[c] for c in cols if row[c] != '']))
            out_writer.writerow(output_row)
