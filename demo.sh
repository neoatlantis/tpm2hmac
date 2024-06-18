#!/bin/bash

tpm2 () {
    tpm2_$1 -Tspi-ltt2go ${@:2}
}

echo -n "test" > test.bin

tpm2 startup -c


echo "Test with 10 random bytes..."
tpm2 getrandom --hex 10

# If we have got a copy of the primary key.
if [ ! -f ./primary.ctx ]; then
    echo "Create primary key..."
    tpm2 createprimary --hierarchy o -c primary.ctx
    # should not be on NULL hierarchy, as we want to reload the key to same primary key.
    tpm2 flushcontext -t
fi

# If we have previously imported the key.
if [ ! -f ./hmac_key.priv ] || [ ! -f ./hmac_key.pub ]; then
    tpm2 flushcontext -t
    tpm2 import -C primary.ctx -G hmac -r hmac_key.priv -u hmac_key.pub -i test.bin -a "stclear"
fi

# Always reload the key and its context...hmac.ctx is volatile upon each flushcontext or reset or resume.
tpm2 load -C primary.ctx -u hmac_key.pub -r hmac_key.priv -c hmac.ctx
cat test.bin | tpm2 hmac -c hmac.ctx --hex

echo "Import done, now lets do some test."

# Now to backup: primary.ctx, hmac_key.*

printf "\n...done\n"
