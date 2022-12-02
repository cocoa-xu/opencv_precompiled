#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from pathlib import Path
import shutil


if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit(1)
    cv_src_root = f"{sys.argv[1]}/modules/"
    header_txt = sys.argv[2]
    headers_dir = Path(f"{sys.argv[3]}/headers")
    with open(header_txt, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith(cv_src_root):
                header_file = Path(line)
                dest_dir = headers_dir / Path(line[len(cv_src_root):]).parent
                if not dest_dir.exists():
                    dest_dir.mkdir(exist_ok=True, parents=True)
                dest_file = dest_dir / header_file.name
                shutil.copy2(header_file, dest_file)
            else:
                raise RuntimeError(f"Header file not copied: {line}")
