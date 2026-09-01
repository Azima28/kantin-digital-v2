import os
from PIL import Image, ImageDraw

def create_base_canvas(size=1024):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    return img, draw

def draw_circle_bg(draw, size, color):
    margin = int(size * 0.02)
    draw.ellipse([margin, margin, size - margin, size - margin], fill=color)

def draw_neck_and_body(draw, size, skin_color, shirt_color, collar_color=None, collar_type="tshirt"):
    cx = size // 2

    # Body / Shoulders
    shoulder_top = int(size * 0.72)
    body_bbox = [int(size * 0.12), shoulder_top, int(size * 0.88), int(size * 1.08)]
    draw.ellipse(body_bbox, fill=shirt_color)

    # Neck
    neck_w = int(size * 0.16)
    neck_top = int(size * 0.58)
    neck_bottom = int(size * 0.76)
    draw.rectangle([cx - neck_w // 2, neck_top, cx + neck_w // 2, neck_bottom], fill=skin_color)

    # Neck shadow
    shadow_color = (int(skin_color[0] * 0.88), int(skin_color[1] * 0.84), int(skin_color[2] * 0.84), 255)
    draw.chord([cx - neck_w // 2, neck_top, cx + neck_w // 2, neck_top + int(size * 0.08)], 0, 180, fill=shadow_color)

    # Collar details
    if collar_type == "tshirt":
        draw.ellipse([cx - int(size * 0.11), shoulder_top - int(size * 0.02), cx + int(size * 0.11), shoulder_top + int(size * 0.09)], fill=shirt_color)
        draw.arc([cx - int(size * 0.11), shoulder_top - int(size * 0.02), cx + int(size * 0.11), shoulder_top + int(size * 0.09)], 0, 180, fill=(255, 255, 255, 60), width=int(size * 0.015))
    elif collar_type == "polo":
        # V-collar
        draw.polygon([(cx - int(size * 0.13), shoulder_top), (cx + int(size * 0.13), shoulder_top), (cx, shoulder_top + int(size * 0.14))], fill=collar_color or shirt_color)
        draw.polygon([(cx - int(size * 0.08), shoulder_top), (cx + int(size * 0.08), shoulder_top), (cx, shoulder_top + int(size * 0.10))], fill=skin_color)
    elif collar_type == "tie":
        # White shirt + Tie
        draw.polygon([(cx - int(size * 0.12), shoulder_top), (cx + int(size * 0.12), shoulder_top), (cx, shoulder_top + int(size * 0.12))], fill=(248, 250, 252, 255))
        # Tie
        tie_color = (13, 148, 136, 255) # Teal
        draw.polygon([(cx - int(size * 0.03), shoulder_top + int(size * 0.05)), (cx + int(size * 0.03), shoulder_top + int(size * 0.05)), (cx + int(size * 0.045), size), (cx - int(size * 0.045), size)], fill=tie_color)

def draw_head_and_face(draw, size, skin_color, blush=True):
    cx = size // 2
    cy = int(size * 0.44)
    rx = int(size * 0.22)
    ry = int(size * 0.25)

    # Ears
    ear_w = int(size * 0.07)
    ear_h = int(size * 0.10)
    ear_y = cy - int(size * 0.02)
    draw.ellipse([cx - rx - ear_w // 2, ear_y, cx - rx + ear_w // 2, ear_y + ear_h], fill=skin_color)
    draw.ellipse([cx + rx - ear_w // 2, ear_y, cx + rx + ear_w // 2, ear_y + ear_h], fill=skin_color)

    # Inner ear detail
    inner_ear = (int(skin_color[0] * 0.9), int(skin_color[1] * 0.8), int(skin_color[2] * 0.8), 255)
    draw.ellipse([cx - rx - ear_w // 4, ear_y + int(ear_h * 0.2), cx - rx + ear_w // 4, ear_y + int(ear_h * 0.7)], fill=inner_ear)
    draw.ellipse([cx + rx - ear_w // 4, ear_y + int(ear_h * 0.2), cx + rx + ear_w // 4, ear_y + int(ear_h * 0.7)], fill=inner_ear)

    # Head Oval
    draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=skin_color)

    # Cheeks blush
    if blush:
        blush_col = (251, 113, 133, 70) # soft rose
        bw = int(size * 0.06)
        bh = int(size * 0.035)
        draw.ellipse([cx - int(rx * 0.65) - bw // 2, cy + int(size * 0.04), cx - int(rx * 0.65) + bw // 2, cy + int(size * 0.04) + bh], fill=blush_col)
        draw.ellipse([cx + int(rx * 0.65) - bw // 2, cy + int(size * 0.04), cx + int(rx * 0.65) + bw // 2, cy + int(size * 0.04) + bh], fill=blush_col)

    # Eyes
    eye_y = cy - int(size * 0.01)
    eye_offset = int(rx * 0.42)
    eye_r = int(size * 0.028)

    # Left eye & Right eye
    draw.ellipse([cx - eye_offset - eye_r, eye_y - eye_r, cx - eye_offset + eye_r, eye_y + eye_r], fill=(30, 41, 59, 255))
    draw.ellipse([cx + eye_offset - eye_r, eye_y - eye_r, cx + eye_offset + eye_r, eye_y + eye_r], fill=(30, 41, 59, 255))

    # Eye highlights
    hl_r = int(eye_r * 0.35)
    draw.ellipse([cx - eye_offset + int(eye_r * 0.1), eye_y - eye_r + int(eye_r * 0.1), cx - eye_offset + int(eye_r * 0.1) + hl_r, eye_y - eye_r + int(eye_r * 0.1) + hl_r], fill=(255, 255, 255, 255))
    draw.ellipse([cx + eye_offset + int(eye_r * 0.1), eye_y - eye_r + int(eye_r * 0.1), cx + eye_offset + int(eye_r * 0.1) + hl_r, eye_y - eye_r + int(eye_r * 0.1) + hl_r], fill=(255, 255, 255, 255))

    # Eyebrows
    brow_y = eye_y - int(size * 0.045)
    brow_w = int(size * 0.06)
    draw.line([cx - eye_offset - brow_w // 2, brow_y, cx - eye_offset + brow_w // 2, brow_y - int(size * 0.008)], fill=(30, 41, 59, 255), width=int(size * 0.012))
    draw.line([cx + eye_offset - brow_w // 2, brow_y - int(size * 0.008), cx + eye_offset + brow_w // 2, brow_y], fill=(30, 41, 59, 255), width=int(size * 0.012))

    # Nose
    nose_y = cy + int(size * 0.04)
    draw.arc([cx - int(size * 0.015), nose_y - int(size * 0.015), cx + int(size * 0.015), nose_y + int(size * 0.015)], 0, 180, fill=(203, 145, 120, 255), width=int(size * 0.008))

    # Mouth / Smile
    mouth_y = cy + int(size * 0.11)
    mouth_w = int(size * 0.06)
    draw.arc([cx - mouth_w, mouth_y - int(size * 0.035), cx + mouth_w, mouth_y + int(size * 0.035)], 20, 160, fill=(225, 29, 72, 255), width=int(size * 0.012))

def draw_boy_hair(draw, size, hair_color=(30, 41, 59, 255)):
    cx = size // 2
    cy = int(size * 0.44)
    rx = int(size * 0.22)
    ry = int(size * 0.25)

    # Top hair mass
    top_hair_bbox = [cx - rx - int(size * 0.03), cy - ry - int(size * 0.08), cx + rx + int(size * 0.03), cy - int(size * 0.05)]
    draw.ellipse(top_hair_bbox, fill=hair_color)

    # Bangs / Textured tufts
    bangs = [
        [(cx - int(rx * 0.9), cy - int(ry * 0.6)), (cx - int(rx * 0.5), cy - int(ry * 0.2)), (cx - int(rx * 0.3), cy - int(ry * 0.6))],
        [(cx - int(rx * 0.4), cy - int(ry * 0.7)), (cx, cy - int(ry * 0.18)), (cx + int(rx * 0.3), cy - int(ry * 0.65))],
        [(cx + int(rx * 0.15), cy - int(ry * 0.7)), (cx + int(rx * 0.6), cy - int(ry * 0.25)), (cx + int(rx * 0.9), cy - int(ry * 0.6))],
    ]
    for b in bangs:
        draw.polygon(b, fill=hair_color)

    # Sideburns
    draw.polygon([(cx - rx - int(size * 0.02), cy - int(size * 0.08)), (cx - rx + int(size * 0.02), cy + int(size * 0.03)), (cx - rx + int(size * 0.04), cy - int(size * 0.08))], fill=hair_color)
    draw.polygon([(cx + rx + int(size * 0.02), cy - int(size * 0.08)), (cx + rx - int(size * 0.02), cy + int(size * 0.03)), (cx + rx - int(size * 0.04), cy - int(size * 0.08))], fill=hair_color)

def draw_girl_hair(draw, size, hair_color=(45, 30, 25, 255), is_hijab=False):
    cx = size // 2
    cy = int(size * 0.44)
    rx = int(size * 0.22)
    ry = int(size * 0.25)

    if is_hijab:
        # Hijab hood & drape
        hijab_color = (20, 184, 166, 255) # Soft Teal
        hijab_outer = [cx - rx - int(size * 0.08), cy - ry - int(size * 0.08), cx + rx + int(size * 0.08), cy + ry + int(size * 0.22)]
        draw.ellipse(hijab_outer, fill=hijab_color)
    else:
        # Long hair behind shoulders
        draw.ellipse([cx - rx - int(size * 0.08), cy - int(size * 0.05), cx + rx + int(size * 0.08), cy + int(size * 0.42)], fill=hair_color)
        # Top hair
        draw.ellipse([cx - rx - int(size * 0.04), cy - ry - int(size * 0.08), cx + rx + int(size * 0.04), cy], fill=hair_color)
        # Soft curved fringe
        draw.chord([cx - rx, cy - ry - int(size * 0.02), cx + rx, cy - int(ry * 0.2)], 0, 180, fill=hair_color)
        # Cute hair clip
        clip_x = cx + int(rx * 0.6)
        clip_y = cy - int(ry * 0.5)
        draw.ellipse([clip_x - int(size * 0.03), clip_y - int(size * 0.015), clip_x + int(size * 0.03), clip_y + int(size * 0.015)], fill=(244, 63, 94, 255))

def draw_chef_hat(draw, size):
    cx = size // 2
    cy = int(size * 0.44)
    rx = int(size * 0.22)
    ry = int(size * 0.25)

    hat_col = (255, 255, 255, 255)
    rim_col = (226, 232, 240, 255)

    # Puffy hat top
    puff_y = cy - ry - int(size * 0.22)
    draw.ellipse([cx - int(size * 0.28), puff_y, cx + int(size * 0.28), puff_y + int(size * 0.30)], fill=hat_col)
    draw.ellipse([cx - int(size * 0.32), puff_y + int(size * 0.08), cx - int(size * 0.08), puff_y + int(size * 0.32)], fill=hat_col)
    draw.ellipse([cx + int(size * 0.08), puff_y + int(size * 0.08), cx + int(size * 0.32), puff_y + int(size * 0.32)], fill=hat_col)

    # Hat band
    band_y = cy - ry - int(size * 0.06)
    draw.rectangle([cx - int(rx * 1.05), band_y, cx + int(rx * 1.05), band_y + int(size * 0.09)], fill=rim_col)
    draw.line([cx - int(rx * 1.05), band_y + int(size * 0.09), cx + int(rx * 1.05), band_y + int(size * 0.09)], fill=(148, 163, 184, 255), width=int(size * 0.008))

def draw_glasses(draw, size):
    cx = size // 2
    cy = int(size * 0.44)
    rx = int(size * 0.22)
    eye_y = cy - int(size * 0.01)
    eye_offset = int(rx * 0.42)
    gr = int(size * 0.055)
    frame_col = (15, 23, 42, 255)

    # Frames
    draw.ellipse([cx - eye_offset - gr, eye_y - gr, cx - eye_offset + gr, eye_y + gr], outline=frame_col, width=int(size * 0.012))
    draw.ellipse([cx + eye_offset - gr, eye_y - gr, cx + eye_offset + gr, eye_y + gr], outline=frame_col, width=int(size * 0.012))
    # Bridge
    draw.line([cx - eye_offset + gr, eye_y, cx + eye_offset - gr, eye_y], fill=frame_col, width=int(size * 0.012))

def generate_all_avatars(output_dir="assets/images/avatars"):
    os.makedirs(output_dir, exist_ok=True)
    size = 1024
    skin_warm = (253, 213, 181, 255)
    skin_fair = (255, 226, 204, 255)

    # 1. Siswa Laki-laki (Boy Student - Like User Screenshot)
    img, draw = create_base_canvas(size)
    draw_circle_bg(draw, size, (241, 245, 249, 255))
    draw_neck_and_body(draw, size, skin_warm, (51, 65, 85, 255), collar_type="tshirt")
    draw_head_and_face(draw, size, skin_warm)
    draw_boy_hair(draw, size, (30, 41, 59, 255))
    img.resize((512, 512), Image.Resampling.LANCZOS).save(f"{output_dir}/avatar_student_boy.png")

    # 2. Siswi Perempuan (Girl Student)
    img, draw = create_base_canvas(size)
    draw_circle_bg(draw, size, (254, 242, 242, 255))
    draw_girl_hair(draw, size, (55, 35, 25, 255))
    draw_neck_and_body(draw, size, skin_fair, (236, 72, 153, 255), collar_type="tshirt")
    draw_head_and_face(draw, size, skin_fair)
    img.resize((512, 512), Image.Resampling.LANCZOS).save(f"{output_dir}/avatar_student_girl.png")

    # 3. Bapak / Orang Tua Laki-laki (Parent Male)
    img, draw = create_base_canvas(size)
    draw_circle_bg(draw, size, (240, 253, 250, 255))
    draw_neck_and_body(draw, size, skin_warm, (30, 58, 138, 255), (241, 245, 249, 255), collar_type="polo")
    draw_head_and_face(draw, size, skin_warm, blush=False)
    draw_boy_hair(draw, size, (30, 41, 59, 255))
    img.resize((512, 512), Image.Resampling.LANCZOS).save(f"{output_dir}/avatar_parent_male.png")

    # 4. Ibu / Orang Tua Perempuan (Parent Female)
    img, draw = create_base_canvas(size)
    draw_circle_bg(draw, size, (253, 244, 255, 255))
    draw_girl_hair(draw, size, (45, 25, 20, 255), is_hijab=True)
    draw_neck_and_body(draw, size, skin_fair, (15, 118, 110, 255), collar_type="tshirt")
    draw_head_and_face(draw, size, skin_fair)
    img.resize((512, 512), Image.Resampling.LANCZOS).save(f"{output_dir}/avatar_parent_female.png")

    # 5. Petugas Kantin (Canteen Chef Operator)
    img, draw = create_base_canvas(size)
    draw_circle_bg(draw, size, (254, 249, 195, 255))
    draw_neck_and_body(draw, size, skin_warm, (234, 88, 12, 255), (255, 255, 255, 255), collar_type="polo")
    draw_head_and_face(draw, size, skin_warm)
    draw_boy_hair(draw, size, (40, 30, 25, 255))
    draw_chef_hat(draw, size)
    img.resize((512, 512), Image.Resampling.LANCZOS).save(f"{output_dir}/avatar_canteen_male.png")

    # 6. Petugas Keuangan (Finance Officer)
    img, draw = create_base_canvas(size)
    draw_circle_bg(draw, size, (240, 253, 244, 255))
    draw_neck_and_body(draw, size, skin_fair, (15, 23, 42, 255), collar_type="tie")
    draw_head_and_face(draw, size, skin_fair)
    draw_boy_hair(draw, size, (30, 41, 59, 255))
    draw_glasses(draw, size)
    img.resize((512, 512), Image.Resampling.LANCZOS).save(f"{output_dir}/avatar_finance.png")

    # 7. Super Admin
    img, draw = create_base_canvas(size)
    draw_circle_bg(draw, size, (238, 242, 255, 255))
    draw_neck_and_body(draw, size, skin_warm, (79, 70, 229, 255), (255, 255, 255, 255), collar_type="polo")
    draw_head_and_face(draw, size, skin_warm, blush=False)
    draw_boy_hair(draw, size, (15, 23, 42, 255))
    # Admin badge lanyard
    cx = size // 2
    draw.line([cx - int(size * 0.1), size, cx, int(size * 0.74)], fill=(245, 158, 11, 255), width=int(size * 0.015))
    draw.line([cx + int(size * 0.1), size, cx, int(size * 0.74)], fill=(245, 158, 11, 255), width=int(size * 0.015))
    img.resize((512, 512), Image.Resampling.LANCZOS).save(f"{output_dir}/avatar_admin.png")

    print("[SUCCESS] All 7 illustrated avatars generated successfully in", output_dir)

if __name__ == "__main__":
    generate_all_avatars()
