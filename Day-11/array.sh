fruits=("Apple" "Banana" "Mango" "Orange")

echo "${fruits[0]}"
echo "${fruits[1]}"
echo "${fruits[2]}"
echo "${fruits[3]}"
echo "${fruits[@]}"
echo "${#fruits[@]}"

fruits+=("Grapes")
echo "${fruits[@]}"
echo "${#fruits[@]}"
