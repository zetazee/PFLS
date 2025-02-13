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
            cp "$fasta_file" "/home/$USER/PFLS-DATA-PACKAGE/EXC-004/COMBINED-DATA/${sample_name}_UNBINNED.fa"
        else
            # Check if the bin is MAG or BIN based on checkm.txt
            fasta_base="${fasta_name%.fasta}"
            status=$(awk -v fasta="$fasta_base" 'NR > 3 {
            split($1, bin_id, "_");  # Split $1 by "_"
            if (bin_id[4] == fasta) {
            if ($13 >= 50 && $15 < 5) print "MAG";
            else print "BIN";
            }
            }' "$dir/checkm.txt")

            echo "File: $fasta_name -> Status: $status"


            if [[ "$status" == "MAG" ]]; then
                new_name="${sample_name}_MAG_$(printf "%03d" $mag_counter).fa"
                mag_counter=$((mag_counter + 1))
            else
                new_name="${sample_name}_BIN_$(printf "%03d" $bin_counter).fa"
                bin_counter=$((bin_counter + 1))
            fi
            
            cp "$fasta_file" "/home/$USER/PFLS-DATA-PACKAGE/EXC-004/COMBINED-DATA/$new_name"
        fi
    done
done
