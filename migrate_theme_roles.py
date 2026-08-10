import os
import re

directories = [
    r"lib/features/keuangan",
    r"lib/features/admin"
]

replacements = [
    (r"Starlight\.bright", "context.textPrimary"),
    (r"Starlight\.default_", "context.textSecondary"),
    (r"Starlight\.dim\.withValues\(alpha: 0\.3\)", "context.dividerCol"),
    (r"Starlight\.dim\.withValues\(alpha: 0\.4\)", "context.dividerCol"),
    (r"Starlight\.dim\.withValues\(alpha: 0\.5\)", "context.dividerCol"),
    (r"Starlight\.dim", "context.textSecondary"),
    (r"Starlight\.faint", "context.textHint"),
    (r"Starlight\.disabled", "context.textHint"),
    (r"Cosmic\.surface", "context.cardBg"),
    (r"Cosmic\.elevated", "context.surfaceBg"),
    (r"Cosmic\.overlay", "context.surfaceBg"),
    (r"Cosmic\.void_\.withValues\(alpha: 0\.04\)", "context.shadowColor"),
    (r"Cosmic\.void_\.withValues\(alpha: 0\.02\)", "context.shadowColor"),
    (r"Cosmic\.void_", "context.textPrimary"),
]

import_statement = "import 'package:kantin_digital/core/extensions/theme_extensions.dart';"

def process_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    original = content
    has_changes = False
    
    for pattern, replacement in replacements:
        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            has_changes = True
            
    if has_changes:
        # Check if theme_extensions import is present
        if "theme_extensions.dart" not in content:
            # Find the last import line
            lines = content.splitlines()
            last_import_idx = -1
            for idx, line in enumerate(lines):
                if line.strip().startswith("import "):
                    last_import_idx = idx
            
            if last_import_idx != -1:
                lines.insert(last_import_idx + 1, import_statement)
                content = "\n".join(lines) + "\n"
            else:
                # If no imports found, insert at the beginning
                content = import_statement + "\n" + content
                
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Processed: {filepath}")

def main():
    for d in directories:
        for root, _, files in os.walk(d):
            for file in files:
                if file.endswith(".dart"):
                    process_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
