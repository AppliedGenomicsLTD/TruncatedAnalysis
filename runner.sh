#!/bin/bash

args=("$@")
echo "con->"  ${args[0]}
echo "alga->" ${args[1]}
echo "R1->"  ${args[2]}
echo "R2->" ${args[3]}

echo ""
mkdir ${args[0]}
echo "made directory" ${args[0]}
echo ""
cp ${args[0]}.fa ${args[0]}/
cd ${args[0]}
samtools faidx ${args[0]}.fa
bwa index ${args[0]}.fa
echo "created bwa index for " ${args[0]}

cd ..
bedtools getfasta -fi ${args[0]}.fa -bed ${args[0]}.regions.bed -name > ${args[0]}.regions.fa
echo "extracted endogenous regions from " ${args[0]}
blastn -db ../Genomes/${args[1]}/${args[1]}.fna -query ${args[0]}.regions.fa -out blast.${args[0]}.regions.out -outfmt "6 qseqid sseqid sstart send evalue bitscore"
python parse.raw.blast.py blast.${args[0]}.regions.out
mkdir algae.masked.blast.${args[0]}
bedtools maskfasta -fi ../../Genomes/${args[1]}/${args[1]}.fna -bed ${args[0]}.blast.algae.bed -fo algae.masked.blast.${args[0]}/algae.masked.blast.${args[0]}.fa
samtools faidx algae.masked.blast.${args[0]}/algae.masked.blast.${args[0]}.fa
bwa index algae.masked.blast.${args[0]}/algae.masked.blast.${args[0]}.fa
echo "created masked fasta for algae"

bwa mem -T 0 -t 8 -M ${args[0]}/${args[0]}.fa ${args[2]} ${args[3]} > ${args[0]}.construct-alignment.T0.sam
samtools view -Sb ${args[0]}.construct-alignment.T0.sam > ${args[0]}.construct-alignment.T0.bam
samtools sort -@8 ${args[0]}.construct-alignment.T0.bam -o ${args[0]}.construct-alignment.T0.sorted.bam
samtools index ${args[0]}.construct-alignment.T0.sorted.bam
echo "aligned T=0 for " ${args[0]}

bwa mem -T 0 -t 8 -M algae.masked.blast.${args[0]}/algae.masked.blast.${args[0]}.fa ${args[2]} ${args[3]} > ${args[0]}.algae-alignment.T0.sam
samtools view -Sb ${args[0]}.algae-alignment.T0.sam > ${args[0]}.algae-alignment.T0.bam
samtools sort -@8 ${args[0]}.algae-alignment.T0.bam -o ${args[0]}.algae-alignment.T0.sorted.bam
samtools index ${args[0]}.algae-alignment.T0.sorted.bam
echo "aligned T=0 for algae"

# java -jar ../jvarkit/dist/samextractclip.jar -c ${args[0]}.construct-alignment.T0.sam > clipped.fq
#
# bwa mem -T 0 -t 8 -M ${args[0]}/${args[0]}.fa clipped.fq > clipped.${args[0]}.sam
# samtools view -Sb clipped.${args[0]}.sam > clipped.${args[0]}.bam
# samtools sort -@8 clipped.${args[0]}.bam -o clipped.${args[0]}.sorted.bam
# samtools index clipped.${args[0]}.sorted.bam
# echo "aligned clipped reads for " ${args[0]}
#
# bwa mem -T 0 -t 8 -M algae.masked.blast.${args[0]}/algae.masked.blast.${args[0]}.fa clipped.fq > clipped.algae.sam
# samtools view -Sb clipped.algae.sam > clipped.algae.bam
# samtools sort -@8 clipped.algae.bam -o clipped.algae.sorted.bam
# samtools index clipped.algae.sorted.bam
# echo "aligned clipped reads for algae"
#
# bedtools genomecov -ibam clipped.algae.sorted.bam -bg | awk '$4>=1' > clipped.algae.sorted.bed
# bedops -m clipped.algae.sorted.bed > clipped.algae.sorted.bg

echo "running tdnascan"
cd TDNAscan-master
python tdnascan.py -1 ../${args[0]}/${args[2]} -2 ../${args[0]}/${args[3]} -g ../${args[0]}/algae.masked.blast.${args[0]}/algae.masked.blast.${args[0]}.fa -t ../${args[0]}/${args[0]}/${args[0]}.fa -p ${args[0]}tdnascan -b 150
