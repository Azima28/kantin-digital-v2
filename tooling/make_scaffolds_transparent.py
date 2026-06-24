import os
import re

def parse_blocks(text, keyword):
    """
    Finds nested block contents starting with a keyword followed by a parenthesis.
    Example: keyword='Scaffold' or keyword='AppBar'
    Returns a list of (start_idx, end_idx, block_text)
    """
    blocks = []
    idx = 0
    while True:
        pos = text.find(keyword, idx)
        if pos == -1:
            break
        # find the opening parenthesis
        open_paren = text.find('(', pos)
        if open_paren == -1 or open_paren > pos + 10:
            idx = pos + len(keyword)
            continue
        # count parentheses to find the matching closing one
        count = 1
        i = open_paren + 1
        while i < len(text) and count > 0:
            if text[i] == '(':
                count += 1
            elif text[i] == ')':
                count -= 1
            i += 1
        block = text[pos:i]
        blocks.append((pos, i, block))
        idx = i
    return blocks

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    modified = False

    # Process Scaffolds
    # We find blocks starting with 'Scaffold'
    scaffold_blocks = parse_blocks(content, 'Scaffold')
    # Process from last to first so indices don't shift
    for start, end, block in reversed(scaffold_blocks):
        # We only want to replace backgroundColor in the Scaffold constructor parameters
        # Let's check if the Scaffold block has scaffold background color parameters
        new_block = block
        for target in [
            'backgroundColor: AppColors.systemBackground',
            'backgroundColor: AppColors.offWhite',
            'backgroundColor: AppColors.scaffoldBackground',
            'backgroundColor: AppColors.white',  # Some screens might use white for Scaffold
        ]:
            if target in block:
                new_block = new_block.replace(target, 'backgroundColor: Colors.transparent')
        
        if new_block != block:
            content = content[:start] + new_block + content[end:]
            modified = True

    # Process AppBars
    appbar_blocks = parse_blocks(content, 'AppBar')
    for start, end, block in reversed(appbar_blocks):
        new_block = block
        for target in [
            'backgroundColor: AppColors.systemBackground',
            'backgroundColor: AppColors.offWhite',
            'backgroundColor: AppColors.scaffoldBackground',
            'backgroundColor: AppColors.cardBackground',
            'backgroundColor: AppColors.white',
        ]:
            if target in block:
                new_block = new_block.replace(target, 'backgroundColor: Colors.transparent')
        
        if new_block != block:
            content = content[:start] + new_block + content[end:]
            modified = True

    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Modified: {filepath}")

def main():
    features_dir = os.path.join("lib", "features")
    for root, dirs, files in os.walk(features_dir):
        # We only care about screen files in screens directories
        if "screens" in root:
            for file in files:
                if file.endswith(".dart"):
                    filepath = os.path.join(root, file)
                    process_file(filepath)

if __name__ == "__main__":
    main()
