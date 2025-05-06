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
KUZU_THIRD_PARTY_DIR = os.path.abspath(os.path.join(KUZU_ROOT_DIR, "third_party"))
KUZU_BUILD_DIR = os.path.abspath(os.path.join(KUZU_ROOT_DIR, "build"))
CXX_KUZU_ROOT_DIR = os.path.abspath(os.path.join(ROOT_DIR, "Sources", CXX_KUZU))
TARGET_DIR = os.path.abspath(os.path.join(CXX_KUZU_ROOT_DIR, KUZU))
TARGET_SRC_DIR = os.path.abspath(os.path.join(TARGET_DIR, "src"))
TARGET_THIRD_PARTY_DIR = os.path.abspath(os.path.join(TARGET_DIR, "third_party"))
OUTPUT_PATH = os.path.abspath(os.path.join(ROOT_DIR, PACKAGE_SWIFT))

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

status = Popen("cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHELL=FALSE -DBUILD_BENCHMARK=FALSE -DBUILD_TESTS=FALSE ..", cwd=KUZU_BUILD_DIR, shell=True).wait()
if status != 0:
    logger.error("Failed to cmake kuzu")
    exit(1)

compile_commands_file = os.path.abspath(os.path.join(KUZU_BUILD_DIR, "compile_commands.json"))
if not os.path.exists(compile_commands_file):
    logger.error("Failed to find compile_commands.json")
    exit(1)
compile_commands = json.load(open(compile_commands_file))

command_to_decode = None
for command in compile_commands:
    if "c_api" in command["directory"]:
        command_to_decode = command["command"]
        break

if command_to_decode is None:
    logger.error("Failed to find c_api in compile_commands.json")
    exit(1)

logger.info("Decoding command...")
command_to_decode = command_to_decode.split(" ")

include_dirs = set()
defines = set()

for command in command_to_decode:
    if command.startswith("-I"):
        include_dir = command.split("-I")[1]
        include_dir = os.path.relpath(include_dir, KUZU_ROOT_DIR)
        include_dir = os.path.join(KUZU, include_dir)
        include_dirs.add(include_dir)

for command in command_to_decode:
    if command.startswith("-D"):
        define = command.split("-D")[1].replace("\\", "")
        if define.startswith("KUZU_ROOT_DIRECTORY"):
            define = define.replace(KUZU_ROOT_DIR, KUZU)
        if define.startswith("__64BIT__") or define.startswith("__32BIT__"):
            continue
        if define == "NDEBUG" or define == "DEBUG":
            continue
        defines.add(define)

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

logger.info("Copying third party dependencies...")
shutil.copytree(KUZU_THIRD_PARTY_DIR, TARGET_THIRD_PARTY_DIR)

logger.info("Copying source code...")
shutil.copytree(KUZU_SRC_DIR, TARGET_SRC_DIR)

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