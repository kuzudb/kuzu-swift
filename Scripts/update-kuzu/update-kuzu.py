import os
import shutil
import sys
from subprocess import Popen
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


KUZU = "kuzu"
REPO_URL = "https://github.com/kuzudb/kuzu.git"
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
KUZU_ROOT_DIR = os.path.abspath(os.path.join(ROOT_DIR, KUZU))
COLLECT_KUZU_SRC_SCRIPT_DIR = os.path.abspath(
    os.path.join(ROOT_DIR, "Scripts", "collect-kuzu-src")
)
COLLECT_KUZU_SRC_SCRIPT_NAME = "collect-kuzu-src.py"
KUZU_BRANCH = os.getenv("KUZU_BRANCH", "")
KUZU_BRANCH = KUZU_BRANCH.strip()
if not KUZU_BRANCH:
    logger.info("KUZU_BRANCH is not set or invalid, using default branch")
    KUZU_BRANCH = "master"
else:
    logger.info(f"KUZU_BRANCH is set to {KUZU_BRANCH}")

PYTHON_EXECUTABLE = sys.executable

if os.path.exists(KUZU_ROOT_DIR):
    logger.info(f"Removing existing {KUZU_ROOT_DIR} directory")
    shutil.rmtree(KUZU_ROOT_DIR)
logger.info(f"Cloning {KUZU} repository from branch {KUZU_BRANCH}")
Popen(
    [
        "git",
        "clone",
        "--branch",
        KUZU_BRANCH,
        "--depth",
        "1",
        "https://github.com/kuzudb/kuzu.git",
        KUZU_ROOT_DIR,
    ],
).wait()

Popen(
    ["git", "checkout", KUZU_BRANCH],
    cwd=KUZU_ROOT_DIR,
).wait()

logger.info(f"Running {COLLECT_KUZU_SRC_SCRIPT_NAME} script")
Popen(
    [PYTHON_EXECUTABLE, COLLECT_KUZU_SRC_SCRIPT_NAME],
    cwd=COLLECT_KUZU_SRC_SCRIPT_DIR,
).wait()
logger.info(f"Update process for {KUZU} completed successfully.")

logger.info("Cleaning up temporary files...")
shutil.rmtree(KUZU_ROOT_DIR, ignore_errors=True)
logger.info("Temporary files cleaned up.")
