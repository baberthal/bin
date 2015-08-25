import os

# go through the whole folder, and add all directories, that contain sourcecode

# Which directories to scan
directories = ("MyFirstObjectiveCProgram", "External", "libs")

def find_all_source_directories(parentDir):
    def directories_contains_source(files):
        for f in files:
            if f.split(".")[-1] in ("h", "m", "mm", "c"):
                return True
        return False
    returnList = []
    for (path, dirs, files) in os.walk(parentDir):
        if directories_contains_source(files):
            returnList.append(path)
    return returnList

def format_directories(directories):
    return "\n".join(['-I"%s"' % (p,) for p in directories])

if __name__ == "__main__":
    codeDirs = []
    for dir in directories:
        codeDirs = codeDirs + find_all_source_directories(dir)
    print format_directories(codeDirs)

