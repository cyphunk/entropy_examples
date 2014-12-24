#!/bin/bash

echo "*** GET SAMPLES ***"

dd if=/dev/random of=random bs=1m count=4
dd if=/dev/zero   of=zero   bs=1m count=4
if [ ! -e "4mbpng" ]; then
    wget -O 4mbpng https://upload.wikimedia.org/wikipedia/en/f/ff/Victoria_Inner_Harbour_HDR.png
fi
if [ ! -e "4mbjpg" ]; then
    wget -O 4mbjpg https://upload.wikimedia.org/wikipedia/commons/1/1e/Caerte_van_Oostlant_4MB.jpg
fi

echo "*** MAKE ENCODE/ENCRYPT EXAMPLES ***"

for alg in des3 bf rc2 rc4 rc5 cast base64; do
    echo $alg random
    openssl $alg -in random -out random.$alg -pass pass:test
    echo $alg zero
    openssl $alg -in zero -out zero.$alg -pass pass:test
    echo $alg 4mbjpg
    openssl $alg -in 4mbjpg -out 4mbjpg.$alg -pass pass:test
    echo $alg 4mbpng
    openssl $alg -in 4mbpng -out 4mbpng.$alg -pass pass:test
done

echo "*** MAKE COMPRESS SAMPLES ***"

zips[0]="gzip -f -c -9 <FILE> > <FILE>.gz"
zips[1]="zip <FILE> <FILE>"
for zip in "${zips[@]}"; do
    cmd=`echo -n $zip | sed 's/<FILE>/zero/g'`
    echo $cmd
    eval $cmd
    cmd=`echo -n $zip | sed 's/<FILE>/random/g'`
    echo $cmd
    eval $cmd
    cmd=`echo -n $zip | sed 's/<FILE>/4mbjpg/g'`
    echo $cmd
    eval $cmd
    cmd=`echo -n $zip | sed 's/<FILE>/4mbpng/g'`
    echo $cmd
    eval $cmd
done

# XOR

if [[ $(command -v xortool-xor) ]]; then
    echo "MAKE XOR SAMPLES"
    key="feeddeadca72bab1" #$(dd if=/dev/random bs=1 count=16 2>/dev/null | xxd -p); # key
	xortool-xor -h $key -f 4mbpng > 4mbpng.xor
	xortool-xor -h $key -f 4mbjpg > 4mbjpg.xor
	xortool-xor -h $key -f zero > zero.xor
	xortool-xor -h $key -f random > random.xor

fi


echo "*** ANALYZE SAMPLES ***"

ls random* zero* 4mb* | xargs analyze.sh --nocleanup
rm -rf *.dat *.md tmp.dot
