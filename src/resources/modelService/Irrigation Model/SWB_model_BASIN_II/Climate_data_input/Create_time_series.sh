
#!/bin/bash

################################################################################
# Create_time_series.sh
#
# This script (for Windows/Git Bash or WSL):
#  1. Unzips climate data archives via PowerShell
#  2. Extracts the time series of a single grid cell to CSV
#  3. Merges CSVs by scenario
#  4. Computes the multi-model average per scenario
#
# Data directory:
#    C:/Users/Andrea/Downloads
################################################################################

set -e  # Exit on any error

# 0. Paths & parameters
DATA_DIR="C:/Users/Andrea/Downloads"
UNZIP_DIR="${DATA_DIR}/unzipped"
EXTRACT_DIR="extracted_csv"
MERGED_DIR="merged_csv"
AVG_DIR="avg_csv"
LON=35.6
LAT=32.1

# -- create a one point grid for nearest neighbour interpolation
cat > coords.txt <<EOF
gridtype = lonlat
xsize    = 1
ysize    = 1
xfirst   = ${LON}
yfirst   = ${LAT}
xinc     = 0
yinc     = 0
EOF

# # Create + clean output dirs
# echo "==> Preparing directories"
# mkdir -p "$UNZIP_DIR" "$EXTRACT_DIR" "$MERGED_DIR" "$AVG_DIR"
# rm -f "$EXTRACT_DIR"/*.csv "$MERGED_DIR"/*.csv "$AVG_DIR"/*.csv

# echo "Using PowerShell Expand-Archive for extraction"

# # 1. Unzip all CS1_*.zip via PowerShell
# echo "==> Unzipping archives to $UNZIP_DIR"
# for zipfile in "$DATA_DIR"/CS1_*.zip; do
    # echo "  Processing: $zipfile"
    # powershell.exe -NoLogo -NoProfile -Command \
        # "Expand-Archive -Path '${zipfile}' -DestinationPath '${UNZIP_DIR}' -Force"
# done

# echo "Unzip complete."

# # 2. Extract point data to CSV
# echo "==> Extracting grid point ($LAT,$LON) to CSV"
# for nc in "$UNZIP_DIR"/*.nc; do
    # fname=$(basename "$nc" .nc)
    # raw=$(echo "$fname" | cut -d'_' -f2)   # raw="tasminAdjust"
    # var=${raw%Adjust}                     # var="tasmin"
    # model=$(echo "$fname" | cut -d'_' -f4)
    # scenario=$(echo "$fname" | cut -d'_' -f5)

    # outcsv="$EXTRACT_DIR/${var}_${model}_${scenario}.csv"
    # echo "  -> $outcsv"

	

    # # inside your loop over .nc files:
     # cdo -s outputtab,date,value \
     # -remapnn,coords.txt \
     # "$nc" \
	 # | grep -v '^#' \
     # | awk -v header="${var}_${model}" \
        # 'BEGIN { print "date," header } { print $1 "," $2 }' \
     # > "$outcsv"
# done

# echo "Extraction complete."

# 3. Merge CSVs by scenario
echo "==> Merging CSVs by scenario"
scenarios=( historical \
            ssp126 \
            ssp370 )
for scen in "${scenarios[@]}"; do
    merged="$MERGED_DIR/${scen}.csv"
    echo "  -> $merged"
    files=( "$EXTRACT_DIR"/*"_${scen}.csv" )

    paste -d',' "${files[@]}" \
      | awk -F',' \
          'NR==1 {                         # header
               printf "%s", $1;
               for(i=2; i<=NF; i+=2) printf ",%s", $i;
               print "";
          }
           NR>1 {                         # rows
               printf "%s", $1;
               for(i=2; i<=NF; i+=2) printf ",%s", $i;
               print "";
          }' \
    > "$merged"
done

echo "Merge complete."




# 4. Compute one per-scenario CSV with averages of all variables
echo "==> Computing per-scenario multi-model averages"
vars=(tasmin tasmax pr hurs)

for merged in "$MERGED_DIR"/*.csv; do
  scen=$(basename "$merged" .csv)
  avgcsv="$AVG_DIR/${scen}_allvars_avg.csv"
  echo "  -> $avgcsv"

  # 4a) Read header and build index lists
  read -r header_line < "$merged"
  IFS=, read -ra header_arr <<< "$header_line"

  # declare associative array to hold space-sep lists of field positions
  declare -A idx_map
  for var in "${vars[@]}"; do
    idxs=()
    for i in "${!header_arr[@]}"; do
      # skip the 'date' column (i=0)
      if [[ $i -gt 0 && "${header_arr[i]}" == ${var}_* ]]; then
        idxs+=( $((i+1)) )   # awk fields are 1-based
      fi
    done
    idx_map[$var]="${idxs[*]}"
  done

  # 4b) Print header and compute averages with a single awk call
  {
    # header
    printf "date"
    for var in "${vars[@]}"; do
      printf ",%s" "$var"
    done
    echo

    # data lines
    awk -F',' -v OFS=',' \
        -v tasmin_idx="${idx_map[tasmin]}" \
        -v tasmax_idx="${idx_map[tasmax]}" \
        -v pr_idx="${idx_map[pr]}" \
        -v hurs_idx="${idx_map[hurs]}" \
    '
    # function to compute average from a space-sep list of field numbers
    function avg(idx_str,   n, a, sum, cnt, f, i) {
      n = split(idx_str, a, " ")
      sum = 0; cnt = 0
      for (i=1; i<=n; i++) {
        f = a[i]
        if ($f != "") { sum += $f; cnt++ }
      }
      return (cnt>0 ? sum/cnt : "")
    }

    NR>1 {
      # print date, then each variable’s average
      printf "%s", $1
      printf "%s", OFS avg(tasmin_idx)
      printf "%s", OFS avg(tasmax_idx)
      printf "%s", OFS avg(pr_idx)
      printf "%s\n", OFS avg(hurs_idx)
    }
    ' "$merged"

  } > "$avgcsv"
done

echo "All per-scenario averages completed."
