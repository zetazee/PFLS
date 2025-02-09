seq_num=$(awk '/>/ {print}' "$1" | wc -l)

total_len=$(awk '!/>/ {printf("%s", $0)}' "$1" | wc -m)

longest_seq=$(awk '/>/{if (NR==1) {print} else{printf("\n%s\n",$0)}next} {printf("%s", $0)}' "$1" | awk '!/>/{if (length > max) max = length; next}END{print max}')

shortest_seq=$(awk '/^>/{if (NR==1) {print} else{printf("\n%s\n", $0)}next} {printf("%s", $0)}' "$1" | awk '!/>/{print length}' "$1" | sort | head -n 1)

sum_len=$(awk '/^>/{if (NR==1) {print} else{printf("\n%s\n", $0)}next} {printf("%s", $0)}' "$1" | awk '!/>/{sum += length}END{print sum}' "$1")
avg_len=$(($sum_len/$seq_num))

G_content=$(grep -o "[Gg]" "$1" | wc -l)
C_content=$(grep -o "[Cc]" "$1" | wc -l)
G_C_content=$(($G_content + $C_content))
GC_content=$(($G_C_content/$total_len))
# bc

echo "FASTA File Statistics:"
echo "----------------------"
echo "Number of sequences: $seq_num"
echo "Total length of sequences: $total_len"
echo "Length of the longest sequence: $longest_seq"
echo "Length of the shortest sequence: $shortest_seq"
echo "Average sequence length: $avg_len"
echo "GC Content (%): $(($GC_content*100))"