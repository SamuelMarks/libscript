import os
import subprocess

def get_sh_files():
    result = subprocess.run(["git", "ls-files", "*.sh"], capture_output=True, text=True)
    return result.stdout.splitlines()

def get_cmd_files():
    result = subprocess.run(["git", "ls-files", "*.cmd"], capture_output=True, text=True)
    return set(result.stdout.splitlines())

def main():
    sh_files = get_sh_files()
    missing_docs = []
    
    for f in sh_files:
        with open(f, 'r') as file:
            content = file.read()
            if "## Overview" not in content and "# " not in content:
                # Let's just check if there is some block of comments that could be docs.
                pass
            if "# ## " not in content and "# #" not in content and "Overview" not in content:
                missing_docs.append(f)
                
    print("Missing docs (first 20):", missing_docs[:20])
    print("Total missing docs:", len(missing_docs))

if __name__ == "__main__":
    main()
