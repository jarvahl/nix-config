#!/usr/bin/env python3

import argparse
import getpass
import hashlib

from argon2.low_level import Type, hash_secret_raw
from bech32 import bech32_encode, convertbits


VERSION = "age-derived-key:v1"


def derive_identity(passphrase: str, context: str) -> str:
    salt = hashlib.sha256((VERSION + ":" + context).encode()).digest()[:16]
    key = hash_secret_raw(
        secret=passphrase.encode(),
        salt=salt,
        time_cost=3,
        memory_cost=256 * 1024,
        parallelism=1,
        hash_len=32,
        type=Type.ID,
    )
    return bech32_encode("age-secret-key-", convertbits(key, 8, 5)).upper()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("context", nargs="?", default="recovery")
    args = parser.parse_args()
    print(derive_identity(getpass.getpass("Passphrase: "), args.context))
