import ctypes
from pathlib import Path

# Adjust this to the built shared library path for your platform.
LIB_NAME = {
    "darwin": "libmusictheory.dylib",
    "linux": "libmusictheory.so",
}.get(__import__("sys").platform, "libmusictheory.so")

lib = ctypes.CDLL(str(Path("zig-out/lib") / LIB_NAME))

lib.lmt_pcs_cardinality.argtypes = [ctypes.c_uint16]
lib.lmt_pcs_cardinality.restype = ctypes.c_uint8

lib.lmt_chord.argtypes = [ctypes.c_uint8, ctypes.c_uint8]
lib.lmt_chord.restype = ctypes.c_uint16

major = lib.lmt_chord(0, 0)
print("C major set:", hex(major), "cardinality:", lib.lmt_pcs_cardinality(major))
