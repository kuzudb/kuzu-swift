import os
import shutil
DEPENDENCIES = [
    "utf8proc",
    "antlr4_cypher",
    "antlr4_runtime",
    "re2",
    "fastpfor",
    "parquet",
    "thrift",
    "snappy",
    "zstd",
    "miniz",
    "mbedtls",
    "brotli",
    "lz4",
    "roaring_bitmap",
    "simsimd",
]

FILE_TYPES = [
    ".cpp",
    ".h",
    ".hpp",
    ".c",
    ".h",
    ".cxx",
    ".hxx",
]

KUZU_SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "kuzu", "src"))
KUZU_THIRD_PARTY_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "kuzu", "third_party"))
TARGET_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "Sources", "cxx-kuzu", "kuzu"))
TARGET_SRC_DIR = os.path.abspath(os.path.join(TARGET_DIR, "src"))
TARGET_THIRD_PARTY_DIR = os.path.abspath(os.path.join(TARGET_DIR, "third_party"))

shutil.rmtree(TARGET_DIR, ignore_errors=True)
os.makedirs(TARGET_DIR, exist_ok=True)
os.makedirs(TARGET_THIRD_PARTY_DIR, exist_ok=True)

for dependency in DEPENDENCIES:
    src_dir = os.path.join(KUZU_THIRD_PARTY_DIR, dependency)
    shutil.copytree(src_dir, os.path.join(TARGET_THIRD_PARTY_DIR, dependency))

shutil.copytree(KUZU_SRC_DIR, TARGET_SRC_DIR)

for folder, subfolders, files in os.walk(TARGET_DIR):
    for file in files:
        
        should_remove = True
        for file_type in FILE_TYPES:
            if file.lower().endswith(file_type):
                should_remove = False
                break
        if should_remove:
            os.remove(os.path.join(folder, file))
