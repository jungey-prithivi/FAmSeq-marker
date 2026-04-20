#/usr/bin/env bash

# conda create -n pmal_mark -c bioconda -c conda-forge bwa samtools bcftools fastqc multiqc mosdepth jupyter ipykernel pandas numpy matplotlib pysam -y

main(){
    set_vars
    initialize
    preqc_and_align
    varcall
    process_vars
}

set_vars(){
    SOURCE=/mnt/storage2/users/ahthapp1/real_deal/pmal_markers
    INPUT=/mnt/storage2/users/ahthapp1/real_deal/pmal_markers/Inputs
    OUTDIR=/mnt/storage2/users/ahthapp1/real_deal/pmal_markers/test_results
    REF=/mnt/storage2/users/ahthapp1/real_deal/MIcrosat/data/GCA_900090045.1/GCA_900090045.1_PmUG01_genomic.fna
    THREADS=4
    BAMLIST=/mnt/storage2/users/ahthapp1/real_deal/pmal_markers/Results1/bam/bamlist.txt
}

initialize(){
    mkdir -p "${OUTDIR}/qc_fastqc" \
            "${OUTDIR}/qc_multiqc" \
            "${OUTDIR}/bam" \
            "${OUTDIR}/qc_bam" \
            "${OUTDIR}/vcf" \
            "${OUTDIR}/logs"

    #checking if all the files are here
    REQ_TOOLS=(bwa samtools bcftools fastqc multiqc mosdepth)
    for t in "${REQ_TOOLS[@]}"; do
        command -v "$t" >/dev/null 2>&1 || { echo "ERROR: missing tool: $t"; exit 1; }
    done

    #make index for bwa if already not done
    if [[ ! -f "${REF}.bwt" ]]; then
        echo "[REF] bwa index"
        bwa index "$REF"
    fi

    #same for sam faidx
    if [[ ! -f "${REF}.fai" ]]; then
        echo "[REF] samtools faidx"
        samtools faidx "$REF"
    fi

    #now getting accession from folder name (IMP: the file is SRA accession and I downloaded from ena ebi from direct link and not with fastqdump)
    #check download script
    #make sure each accesion folder has paired fastq with gzipped fasq file with suffix _1.fastq.gz and _2.fastq.gz
    #maybe add file size filter here###
    mapfile -t ACC_DIRS < <(find "$INPUT" -mindepth 1 -maxdepth 1 -type d | sort)
    if [[ "${#ACC_DIRS[@]}" -eq 0 ]]; then
        echo "ERROR: No accession subfolders found in $INPUT"
        exit 1
    fi

}


preqc_and_align(){
for d in "${ACC_DIRS[@]}"; do
	acc="$(basename "$d")"

	r1="${d}/${acc}_1.fastq.gz"
	r2="${d}/${acc}_2.fastq.gz"

	if [[ -z "${r1:-}" || -z "${r2:-}" || ! -f "$r1" || ! -f "$r2" ]]; then
        echo "WARNING: Skipping $acc (paired fastqs not found in $d)"
        continue
	fi

	echo "[RUN] starts for Sample: $acc -- FastQ initialized. Starting now!:"

    echo "[PRE QC] FastQC"
    echo -e "\tRunning command:"
    echo -e "\t\tfastqc -t $THREADS -o $OUTDIR/qc_fastqc $r1 $r2"
    # -------------------------------------------------------
    fastqc -t "$THREADS" -o "${OUTDIR}/qc_fastqc" "$r1" "$r2"
    # -------------------------------------------------------

    echo "[ALIGNMENT] Bwa, adding read group, sorting and Picard marking dups"
    echo -e "\tRunning command:"
    echo -e "\t\tbwa mem -t $THREADS -R $rg $REF $r1 $r2 | samtools sort -@ $THREADS -o $bam -"
    # -------------------------------------------------------
    bam="${OUTDIR}/bam/${acc}.sorted.bam"
    if [[ ! -f "$bam" ]]; then
        echo "[ALIGN] bwa mem -> sort"
        # adding read group here
        rg="@RG\tID:${acc}\tSM:${acc}\tPL:ILLUMINA"
        bwa mem -t "$THREADS" -R "$rg" "$REF" "$r1" "$r2" \
        | samtools sort -@ "$THREADS" -o "$bam" -
    fi
    # -------------------------------------------------------
}