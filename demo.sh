#!/bin/bash

tpm2 () {
    tpm2_$1 -Tspi-ltt2go ${@:2}
}

echo -n "test" > test.bin

tpm2 startup -c


echo "Test with 10 random bytes..."
tpm2 getrandom --hex 10

if [ ! -f ./primary.ctx ]; then
    echo "Create primary key..."
    tpm2 createprimary --hierarchy n -c primary.ctx
    tpm2 flushcontext -t
fi

if [ ! -f ./hmac.ctx ]; then
    tpm2 flushcontext -t

    tpm2 import -C primary.ctx -G hmac -r hmac_key.priv -u hmac_key.pub -i test.bin
    tpm2 load -C primary.ctx -u hmac_key.pub -r hmac_key.priv -c hmac.ctx
    tpm2 flushcontext -t
fi

echo "Import done, now lets do some test."
cat test.bin | tpm2 hmac -c hmac.ctx --hex


printf "\n...done\n"
