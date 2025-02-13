if ! command -v anvi-script-reformat-fasta &> /dev/null; then
    echo "Error: Please install Anvi'o before running this script."
    exit 1
fi

mkdir -p /home/$USER/PFLS-DATA-PACKAGE/EXC-004/COMBINED-DATA
s_path="/home/$USER/PFLS-DATA-PACKAGE/EXC-004/RAW-DATA"

for dir in "$s_path"/DNA*; do
    lib_name=$(basename "$dir")
    sample_name=$(awk -v dir_name="$lib_name" '$1 == dir_name {print $2}' "$s_path/sample-translation.txt")
    
    echo "Library: $lib_name -> Sample: $sample_name"
    
    cp "$dir/checkm.txt" "/home/$USER/PFLS-DATA-PACKAGE/EXC-004/COMBINED-DATA/${sample_name}-CHECKM.txt"
    cp "$dir/gtdb.gtdbtk.tax" "/home/$USER/PFLS-DATA-PACKAGE/EXC-004/COMBINED-DATA/${sample_name}-GTDB-TAX.txt"

    mag_counter=1
    bin_counter=1

    for fasta_file in "$dir/bins/"*.fasta; do
        fasta_name=$(basename "$fasta_file")
        
        if [[ "$fasta_name" == "bin-unbinned.fasta" ]]; then
            # For the unbinned file, reformat it with the sample name as a prefix.
            anvi-script-reformat-fasta --prefix "$sample_name" \
                -o "/home/$USER/PFLS-DATA-PACKAGE/EXC-004/COMBINED-DATA/${sample_name}_UNBINNED.fa" \
                "$fasta_file"
        else
            # Use the original file (or process it if needed).
            input_fasta="$fasta_file"

            fasta_base="${fasta_name%.fasta}"

            # Count the total lines in checkm.txt.
            total_lines=$(wc -l < "$dir/checkm.txt")

            # Process checkm.txt excluding the first three lines and the last two lines. (fix this)
            status=$(awk -v fasta="$fasta_base" -v total="$total_lines" 'NR > 3 && NR <= total - 2 {
                split($1, bin_id, "_");
                if (bin_id[4] == fasta) {
                    if ($13 >= 50 && $15 < 5)
                        print "MAG";
                    else
                        print "BIN";
                }
            }' "$dir/checkm.txt")

            echo "File: $fasta_name -> Status: $status"

            # Create a new file name based on the status.
            if [[ "$status" == "MAG" ]]; then
                new_name="${sample_name}_MAG_$(printf "%03d" $mag_counter).fa"
                mag_counter=$((mag_counter + 1))
            else
                new_name="${sample_name}_BIN_$(printf "%03d" $bin_counter).fa"
                bin_counter=$((bin_counter + 1))
            fi

            # Reformat the FASTA file with the sample name added as a prefix.
            anvi-script-reformat-fasta --prefix "$sample_name" \
                -o "/home/$USER/PFLS-DATA-PACKAGE/EXC-004/COMBINED-DATA/$new_name" \
                "$input_fasta"
        fi
    done
done
