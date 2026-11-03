# -*- coding: utf-8 -*-
"""Génère les données de chaque set de draft pour l'app.

Pour chaque dossier tool/sets/<id>/ (set.json, draftmancer.txt, scores.py), écrit :
    assets/sets/<id>/data.json   cartes notées, layouts et feuilles de boosters
    assets/sets/sets.json        la liste des sets proposés dans l'app

Usage :
    python3 tool/build_data.py                 # tous les sets
    python3 tool/build_data.py usurp           # un seul set
    python3 tool/build_data.py --images        # + télécharge et redimensionne les images manquantes (Pillow requis)
"""
import importlib.util
import json
import os
import re
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SETS_SRC = os.path.join(ROOT, "tool", "sets")
SETS_OUT = os.path.join(ROOT, "assets", "sets")


def parse(src):
    """Lit un fichier de liste personnalisée Draftmancer : [CustomCards], [Layouts], puis les feuilles."""
    a = src.index("[CustomCards]") + len("[CustomCards]")
    b = src.index("[Layouts]")
    cards = json.loads(src[a:b])
    after = src[b + len("[Layouts]"):]
    first_sheet = re.search(r"\n\[\w+\]\n", after)
    lay_txt = after[:first_sheet.start()]
    layouts = [
        {"name": m.group(1), "w": int(m.group(2)),
         "slots": [[int(x.split()[0]), x.split()[1]] for x in m.group(3).strip().split("\n")]}
        for m in re.finditer(r"- (\S+) \((\d+)\)\n((?:\s+\d+ \S+\n?)+)", lay_txt)
    ]
    sheets, cur = {}, None
    for line in after[first_sheet.start() + 1:].split("\n"):
        line = line.strip()
        if not line:
            continue
        m = re.match(r"^\[(\w+)\]$", line)
        if m:
            cur = m.group(1)
            sheets[cur] = []
            continue
        n, name = line.split(" ", 1)
        sheets[cur].append([int(n), name])
    return cards, layouts, sheets


def load_scores(path):
    spec = importlib.util.spec_from_file_location("scores", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def fetch_images(cards, out_dir):
    from PIL import Image  # import local : seulement pour --images
    os.makedirs(out_dir, exist_ok=True)
    for c in cards:
        dst = os.path.join(out_dir, c["collector_number"] + ".webp")
        if os.path.exists(dst):
            continue
        tmp = dst + ".raw"
        urllib.request.urlretrieve(c["image_uris"]["en"], tmp)
        im = Image.open(tmp).convert("RGB")
        w = 320
        im.resize((w, round(im.height * w / im.width)), Image.LANCZOS).save(dst, "WEBP", quality=72)
        os.remove(tmp)
        print("image", c["collector_number"])


def build_set(set_id, images):
    src_dir = os.path.join(SETS_SRC, set_id)
    meta = json.load(open(os.path.join(src_dir, "set.json"), encoding="utf-8"))
    cards, layouts, sheets = parse(open(os.path.join(src_dir, "draftmancer.txt"), encoding="utf-8").read())
    scores = load_scores(os.path.join(src_dir, "scores.py"))
    missing = [c["name"] for c in cards if c["name"] not in scores.S]
    if missing:
        sys.exit(f"[{set_id}] cartes sans note dans scores.py : " + ", ".join(missing))
    out_dir = os.path.join(SETS_OUT, set_id)
    if images:
        fetch_images(cards, os.path.join(out_dir, "cards"))
    out = []
    for c in cards:
        m = re.search(r"\((red|yellow|blue)\)$", c["name"])
        score, reason = scores.S[c["name"]]
        out.append({
            "name": c["name"], "id": c["collector_number"], "rarity": c["rarity"], "type": c["type"],
            "pitch": {"red": 1, "yellow": 2, "blue": 3}.get(m.group(1)) if m else 0,
            "hero": scores.hero(c), "score": score, "reason": reason,
        })
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "data.json"), "w", encoding="utf-8") as f:
        json.dump({"set": meta, "cards": out, "layouts": layouts, "sheets": sheets}, f, ensure_ascii=False)
    print(f"[{set_id}] {len(out)} cartes, {len(layouts)} layouts, {len(sheets)} feuilles")
    return meta


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    images = "--images" in sys.argv
    all_ids = sorted(d for d in os.listdir(SETS_SRC) if os.path.isdir(os.path.join(SETS_SRC, d)))
    for set_id in args or all_ids:
        build_set(set_id, images)
    # L'index liste tous les sets dont les données existent, même si un seul a été régénéré.
    index = [json.load(open(os.path.join(SETS_SRC, s, "set.json"), encoding="utf-8"))
             for s in all_ids if os.path.exists(os.path.join(SETS_OUT, s, "data.json"))]
    with open(os.path.join(SETS_OUT, "sets.json"), "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=2)
    print("sets.json :", ", ".join(s["id"] for s in index))


if __name__ == "__main__":
    main()
