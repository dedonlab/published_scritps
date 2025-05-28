#!/bin/bash
set -e
readin1=$1
readin2=$2
qname=$3
if [[ -z "$4" ]] ; then
  ref_file='/scratch/users/yfyuan/bbmap/resources/adapters_6Takaraindependt.fa'
else
  ref_file=$4
fi

dir_read=$(cd "$(dirname "$readin1")" ; pwd -P)
export PATH=/scratch/users/yfyuan/bbmap:$PATH
# recommond thread >= 10 ; RAM >= 55G.

#
<<"####"
# 1 create adapter file.
echo '>Read 1a' >$ref_file
echo 'TTTTTTTTTTTTTTTAGATCGGAAGAGCACACGTCTGAACTCCAGTCA' >> $ref_file
echo '>Read 1b' >>$ref_file
echo 'AGATCGGAAGAGCACACGTCTGAACTCCAGTCA' >> $ref_file
echo '>Read 2' >> $ref_file
echo "AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT" >> $ref_file

# 1 trim adapters.
# 1.1 cutadapter R1.
# trim the most left 6 nt.
/scratch/users/yfyuan/bbmap/bbduk.sh -Xmx50g \
in=${readin1} \
out=${dir_read}/${qname}_1_cutadaptor.fq \
ref=${ref_file} \
ktrim=r k=18 hdist=2 hdist2=1 rcomp=f mink=8 \
qtrim=r trimq=30 \
ftl=6 threads=10

>&2 echo -e "${readin1} cut done\t\c"

# 1.2 cutadapter R2 , differnt mink with R1
/scratch/users/yfyuan/bbmap/bbduk.sh -Xmx50g \
in=${readin2} \
out=${dir_read}/${qname}_2_cutadaptor.fq \
ref=${ref_file} \
ktrim=r k=18 mink=8 hdist=1 rcomp=f \
qtrim=r trimq=30 \
threads=10

>&2 echo -e "${readin2} cut done\t\c"

####
<<'####'
# 2 trim poly(A/T)

# 2.1 trim R1.
echo '>Read 1' >$ref_file
echo 'TTTTTTTTTTTTTTTT' >> $ref_file
/scratch/users/yfyuan/bbmap/bbduk.sh -Xmx50g \
in=${dir_read}/${qname}_1_cutadaptor.fq \
out=${dir_read}/${qname}_1_cut.fq \
ref=${ref_file} \
ktrim=r k=15 hdist=1 rcomp=f mink=8 \
threads=10

>&2 echo -e "${readin1} cut done\t\c"

# 2.2 trim R2.ktrim=l
echo '>Read 2' > $ref_file
echo "AAAAAAAAAAAAAAAA" >> $ref_file
/scratch/users/yfyuan/bbmap/bbduk.sh -Xmx50g \
in=${dir_read}/${qname}_2_cutadaptor.fq \
out=${dir_read}/${qname}_2_cut.fq \
ref=${ref_file} \
ktrim=l k=15 hdist=1 rcomp=f mink=8 \
threads=10

mv ${dir_read}/${qname}_1_cut.fq ${dir_read}/${qname}_1_cutadaptor.fq
mv ${dir_read}/${qname}_2_cut.fq ${dir_read}/${qname}_2_cutadaptor.fq

>&2 echo -e "${readin2} cut done\t\c"

## 3 repair R1 and R2.
# repair
/scratch/users/yfyuan/bbmap/repair.sh -Xmx50g \
in1=${dir_read}/${qname}_1_cutadaptor.fq \
in2=${dir_read}/${qname}_2_cutadaptor.fq \
out1=${dir_read}/${qname}_1_cut_repair.fq \
out2=${dir_read}/${qname}_2_cut_repair.fq \
outs=/dev/null \
overwrite=true repair

# tbo
/scratch/users/yfyuan/bbmap/bbduk.sh -Xmx50g \
in1=${dir_read}/${qname}_1_cut_repair.fq \
in2=${dir_read}/${qname}_2_cut_repair.fq \
out1=${dir_read}/${qname}_1_cut_tbo.fq \
out2=${dir_read}/${qname}_2_cut_tbo.fq \
threads=10 tbo overwrite=true minlen=35

>&2 echo "tbo done"
####

#<<'####'
## 4 mask spike-in
refseqPhix='/scratch/users/yfyuan/bbmap/resources/PhiX/Illumina/RTA/Sequence/WholeGenomeFasta/genome.fa'
bbduk.sh in=${dir_read}/${qname}_1_cut_tbo.fq out=${dir_read}/${qname}_1_cut_clean.fq outm=/dev/null ref=$refseqPhix k=31 hdist=1 stats=${dir_read}/${qname}_1_phix_stats.txt

bbduk.sh in=${dir_read}/${qname}_2_cut_tbo.fq out=${dir_read}/${qname}_2_cut_clean.fq outm=/dev/null ref=$refseqPhix k=31 hdist=1 stats=${dir_read}/${qname}_2_phix_stats.txt

# repair
/scratch/users/yfyuan/bbmap/repair.sh -Xmx50g \
in1=${dir_read}/${qname}_1_cut_clean.fq \
in2=${dir_read}/${qname}_2_cut_clean.fq \
out1=${dir_read}/${qname}_1_cut_clean_repair.fq \
out2=${dir_read}/${qname}_2_cut_clean_repair.fq \
outs=/dev/null \
overwrite=true repair

## 5 mask human
ref_genome=/scratch/users/yfyuan/genomes/human/hg19_main_mask_ribo_animal_allplant_allfungus.fa.gz

# step 1 index ref genome
#bbmap.sh ref=$ref_genome -Xmx23g

# step 2 mask human reads
# http://seqanswers.com/forums/showthread.php?t=42552

human1=${dir_read}/${qname}'_R1_human.fq'
human2=${dir_read}/${qname}'_R2_human.fq'

clean1=${dir_read}/${qname}'_R1_clean.fq'
clean2=${dir_read}/${qname}'_R2_clean.fq'

masked='/scratch/users/yfyuan/genomes/human/'

bbmap.sh -Xmx50g minid=0.96 maxindel=2 bwr=0.16 bw=12 quickmatch fast printunmappedcount minhits=2 path=$masked \
in=${dir_read}/${qname}_1_cut_clean_repair.fq \
in2=${dir_read}/${qname}_2_cut_clean_repair.fq \
outu=$clean1 outu2=$clean2 outm=$human1 outm2=$human2 \

## 6 repair R1 and R2.
# repair
/scratch/users/yfyuan/bbmap/repair.sh -Xmx50g \
in1=${dir_read}/${qname}'_R1_clean.fq' \
in2=${dir_read}/${qname}'_R2_clean.fq' \
out1=${dir_read}/${qname}_R1_final.fastq \
out2=${dir_read}/${qname}_R2_final.fastq \
outs=/dev/null \
overwrite=true minlen=35 repair

# 7 fastqc.
module add c3ddb/fastqc/0.11.8
fastqc ${dir_read}/${qname}_R1_final.fastq -o .
fastqc ${dir_read}/${qname}_R2_final.fastq -o .
####
