#/usr/bin/env bash

main(){
    set_vars
    initialize
    run_qc
    get_bams
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
}