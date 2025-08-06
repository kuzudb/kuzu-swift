import os
import shutil
import json
from subprocess import Popen
import logging
from string import Template
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger(__name__)

INDENTATION = "    "*4

KUZU = "kuzu"
CXX_KUZU = "cxx-kuzu"
PACKAGE_SWIFT = "Package.swift"

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
KUZU_ROOT_DIR = os.path.abspath(os.path.join(ROOT_DIR, KUZU))
KUZU_SRC_DIR = os.path.abspath(os.path.join(KUZU_ROOT_DIR, "src"))
KUZU_EXTENSION_DIR = os.path.abspath(os.path.join(KUZU_ROOT_DIR, "extension"))
KUZU_THIRD_PARTY_DIR = os.path.abspath(os.path.join(KUZU_ROOT_DIR, "third_party"))
KUZU_BUILD_DIR = os.path.abspath(os.path.join(KUZU_ROOT_DIR, "build"))
KUZU_C_HEADER = os.path.abspath(os.path.join(KUZU_SRC_DIR, "include", "c_api", "kuzu.h"))
CXX_KUZU_ROOT_DIR = os.path.abspath(os.path.join(ROOT_DIR, "Sources", CXX_KUZU))
TARGET_DIR = os.path.abspath(os.path.join(CXX_KUZU_ROOT_DIR, KUZU))
TARGET_SRC_DIR = os.path.abspath(os.path.join(TARGET_DIR, "src"))
TARGET_EXTENSION_DIR = os.path.abspath(os.path.join(TARGET_DIR, "extension"))
TARGET_THIRD_PARTY_DIR = os.path.abspath(os.path.join(TARGET_DIR, "third_party"))
TARGET_INCLUDE_DIR = os.path.abspath(os.path.join(CXX_KUZU_ROOT_DIR, "include"))
OUTPUT_PATH = os.path.abspath(os.path.join(ROOT_DIR, PACKAGE_SWIFT))
MANUAL_INCLUDE_DIRS = [
    "kuzu/third_party/simsimd/include",
]
MANUAL_SRC_COPY = [
    "build/src/extension/codegen/",
]

FILE_TYPES = [
    '.c',
    '.h',
    '.cpp',
    '.hpp',
    '.cxx',
    '.hxx',
    '.cc',
    '.hh',
    '.tcc',
]
LICENSE_FILE = "LICENSE"

PACKAGE_SWIFT_TEMPLATE = os.path.abspath(os.path.join(os.path.dirname(__file__), f"{PACKAGE_SWIFT}.template"))
try:
    with open(PACKAGE_SWIFT_TEMPLATE, "r") as f:
        PACKAGE_SWIFT_TEMPLATE = f.read()
except FileNotFoundError:
    logger.error("Failed to find Package.swift.template")
    exit(1)

PACKAGE_SWIFT_TEMPLATE = Template(PACKAGE_SWIFT_TEMPLATE)

logger.info("Cleaning build directory...")
status = Popen("make clean", cwd=KUZU_ROOT_DIR, shell=True).wait()
if status != 0:
    logger.error("Failed to clean build directory")
    exit(1)

logger.info("Generating cmake compile commands...")
os.makedirs(KUZU_BUILD_DIR, exist_ok=True)

status = Popen("cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHELL=FALSE -DBUILD_BENCHMARK=FALSE -DBUILD_TESTS=FALSE -DBUILD_SWIFT=TRUE ..", cwd=KUZU_BUILD_DIR, shell=True).wait()
if status != 0:
    logger.error("Failed to cmake kuzu")
    exit(1)

compile_commands_file = os.path.abspath(os.path.join(KUZU_BUILD_DIR, "compile_commands.json"))
if not os.path.exists(compile_commands_file):
    logger.error("Failed to find compile_commands.json")
    exit(1)
compile_commands = json.load(open(compile_commands_file))

logger.info("Decoding commands...")
include_dirs = set()
defines = set()
command_to_decode = None
for command in compile_commands:
    command_to_decode = command["command"]
    command_to_decode = command_to_decode.split(" ")
    for arg in command_to_decode:
        if arg.startswith("-I"):
            include_dir = arg.split("-I")[1]
            include_dir = os.path.relpath(include_dir, KUZU_ROOT_DIR)
            include_dir = os.path.join(KUZU, include_dir)
            include_dirs.add(include_dir)
    for arg in command_to_decode:
        if arg.startswith("-D"):
            define = arg.split("-D")[1].replace("\\", "")
            if define.startswith("KUZU_ROOT_DIRECTORY"):
                define = define.replace(KUZU_ROOT_DIR, KUZU)
            # Skip defines that are not relevant to the build
            if define.startswith("__64BIT__") or define.startswith("__32BIT__"):
                continue
            if define == "NDEBUG" or define == "DEBUG" or define == "OS_MACOSX":
                continue
            if define == "HAVE_STDINT_H":
                continue
            defines.add(define)
    
include_dirs = include_dirs.union(MANUAL_INCLUDE_DIRS)

files_to_compile = set()
for command in compile_commands:
    file_path = command["file"]
    file_relative_path = os.path.relpath(file_path, KUZU_ROOT_DIR)
    file_relative_path = os.path.join(KUZU, file_relative_path)
    files_to_compile.add(file_relative_path)

logger.info("Files to compile: %d", len(files_to_compile))
logger.info("Include dirs: %d", len(include_dirs))
logger.info("Definitions: %d", len(defines))

shutil.rmtree(TARGET_DIR, ignore_errors=True)
os.makedirs(TARGET_DIR, exist_ok=True)
os.makedirs(TARGET_INCLUDE_DIR, exist_ok=True)
logger.info("Copying third party dependencies...")
shutil.copytree(KUZU_THIRD_PARTY_DIR, TARGET_THIRD_PARTY_DIR)

logger.info("Copying source code...")
shutil.copytree(KUZU_SRC_DIR, TARGET_SRC_DIR)

logger.info("Copying extension code...")
shutil.copytree(KUZU_EXTENSION_DIR, TARGET_EXTENSION_DIR)

logger.info("Copying include code...")
shutil.copy(KUZU_C_HEADER, TARGET_INCLUDE_DIR)

logger.info("Copying manually-defined source code...")
for src in MANUAL_SRC_COPY:
    src_path = os.path.join(KUZU_ROOT_DIR, src)
    if os.path.exists(src_path):
        shutil.copytree(src_path, os.path.join(TARGET_DIR, src))
    else:
        logger.error("Source path %s does not exist", src_path)
        exit(1)

logger.info("Removing unneeded files...")
for root, dirs, files in os.walk(TARGET_DIR):
    for file in files:
        if file.upper().startswith(LICENSE_FILE):
            continue
        if any(file.endswith(ext) for ext in FILE_TYPES):
            continue
        os.remove(os.path.join(root, file))

logger.info("Removing empty directories...")
for path, _, _ in os.walk(TARGET_DIR, topdown=False):
    if len(os.listdir(path)) == 0:
        os.rmdir(path)

logger.info("Done removing unneeded files")

logger.info("Generating Package.swift...")
swift_defines = []
swift_sources = []
swift_includes = []

for macro in sorted(defines): 
    if '=' in macro:
        name, value = macro.split('=', 1)
        value = value.strip()
        if value.startswith('"'):
            value = value[1:]
        if value.endswith('"'):
            value = value[:-1]
        if not value:
            swift_defines.append(f'{INDENTATION}.define("{name.strip()}", to: ""),')
        else:
            swift_defines.append(f'{INDENTATION}.define("{name.strip()}", to: "\\"{value}\\""),')
    else:
        swift_defines.append(f'{INDENTATION}.define("{macro.strip()}"),')


swift_sources = [f'{INDENTATION}"{f}",' for f in files_to_compile]
swift_sources = sorted(swift_sources)
swift_includes = [f'{INDENTATION}.headerSearchPath("{include}"),' for include in include_dirs]
swift_includes = sorted(swift_includes)
sources = "\n".join(swift_sources)
cxx_settings = "\n".join(swift_includes)
cxx_settings += "\n"
cxx_settings += "\n".join(swift_defines)

if sources.endswith(","):
    sources = sources[:-1]
if cxx_settings.endswith(","):
    cxx_settings = cxx_settings[:-1]

file_content_to_write = PACKAGE_SWIFT_TEMPLATE.substitute(SOURCES=sources, CXX_SETTINGS=cxx_settings)
logger.info("File size: %d", len(file_content_to_write))
logger.info("Writing Package.swift...")
with open(OUTPUT_PATH, "w") as f:
    f.write(file_content_to_write)

logger.info("Done")
