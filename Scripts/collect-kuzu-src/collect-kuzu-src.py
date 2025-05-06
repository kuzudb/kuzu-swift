import os
import shutil
import json
from subprocess import Popen
import logging

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger(__name__)

KUZU = "kuzu"
CXX_KUZU = "cxx-kuzu"

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
KUZU_ROOT_DIR = os.path.abspath(os.path.join(ROOT_DIR, KUZU))
KUZU_SRC_DIR = os.path.abspath(os.path.join(KUZU_ROOT_DIR, "src"))
KUZU_THIRD_PARTY_DIR = os.path.abspath(os.path.join(KUZU_ROOT_DIR, "third_party"))
KUZU_BUILD_DIR = os.path.abspath(os.path.join(KUZU_ROOT_DIR, "build"))
CXX_KUZU_ROOT_DIR = os.path.abspath(os.path.join(ROOT_DIR, "Sources", CXX_KUZU))
TARGET_DIR = os.path.abspath(os.path.join(CXX_KUZU_ROOT_DIR, KUZU))
TARGET_SRC_DIR = os.path.abspath(os.path.join(TARGET_DIR, "src"))
TARGET_THIRD_PARTY_DIR = os.path.abspath(os.path.join(TARGET_DIR, "third_party"))


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

logger.info("Cleaning build directory...")
status = Popen("make clean", cwd=KUZU_ROOT_DIR, shell=True).wait()

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
            define = define.replace(KUZU_ROOT_DIR, TARGET_DIR)
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

