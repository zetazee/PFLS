if ! command -v anvi-script-reformat-fasta &> /dev/null; then
    echo "Error: Please install Anvi'o before running this script."
    exit 1
fi

mkdir -p ./COMBINED-DATA
s_path="./RAW-DATA"

for dir in "$s_path"/DNA*; do
    lib_name=$(basename "$dir")
    sample_name=$(awk -v dir_name="$lib_name" '$1 == dir_name {print $2}' "$s_path/sample-translation.txt")
    
    echo "Library: $lib_name -> Sample: $sample_name"
    
    cp "$dir/checkm.txt" "./COMBINED-DATA/${sample_name}-CHECKM.txt"
    cp "$dir/gtdb.gtdbtk.tax" "./COMBINED-DATA/${sample_name}-GTDB-TAX.txt"

    mag_counter=1
    bin_counter=1

    for fasta_file in "$dir/bins/"*.fasta; do
        fasta_name=$(basename "$fasta_file")
        
        if [[ "$fasta_name" == "bin-unbinned.fasta" ]]; then
            # For the unbinned file, reformat it with the sample name as a prefix.
            anvi-script-reformat-fasta --prefix "$sample_name" \
                -o "./COMBINED-DATA/${sample_name}_UNBINNED.fa" \
                "$fasta_file"
        else
            input_fasta="$fasta_file"
            fasta_base="${fasta_name%.fasta}"

            status=$(awk '/bin-/' "$dir/checkm.txt" | awk -v fasta="$fasta_base" '{
                split($1, bin_id, "_");
                if (bin_id[4] == fasta) {
                    if ($13 >= 50 && $14 < 5)
                        print "MAG";
                    else
                        print "BIN";
                }
            }')
            
            echo "File: $fasta_name -> Status: $status"

            if [[ "$status" == "MAG" ]]; then
                new_name="${sample_name}_MAG_$(printf "%03d" $mag_counter).fa"
                mag_counter=$((mag_counter + 1))
            else
                new_name="${sample_name}_BIN_$(printf "%03d" $bin_counter).fa"
                bin_counter=$((bin_counter + 1))
            fi

            anvi-script-reformat-fasta --prefix "$sample_name" \
                -o "./COMBINED-DATA/$new_name" \
                "$input_fasta"
        fi
    done
done
