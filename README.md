# P1P1 Dracailles

Entraînement au premier pick (P1P1) en draft Flesh and Blood *Usurp the Shadow Throne*.
L'app ouvre un booster tiré selon la répartition Draftmancer IAR V2.1, tu prends une carte,
et elle te dit si c'était le meilleur choix, avec le tier (S à D) et l'explication de chaque carte.

Android et web (Flutter).

## Commandes

```bash
make help
```

| Commande | Rôle |
|---|---|
| `make data` | Régénère `assets/sets/<id>/data.json` et `assets/sets/sets.json` depuis `tool/sets/<id>/` |
| `make images` | Pareil, et télécharge les images de cartes manquantes (Pillow requis) |
| `make android-run DEVICE=<id>` | Lance l'app en debug sur un appareil |
| `make android-install DEVICE=<id>` | Compile l'APK release et l'installe |
| `make web-serve` | Compile le web et le sert sur http://localhost:8765 |
| `make check` | `pub get` + format + analyse + tests |

## Modifier une note

Les notes (0-100) et les explications sont dans `tool/sets/<id>/scores.py`. Après modification : `make data`.
Le tier affiché découle de la note : S ≥ 88, A ≥ 76, B ≥ 64, C ≥ 52, D en dessous.

## Ajouter un set

1. Créer `tool/sets/<id>/` avec `set.json` (id, name, code, tierNote), `draftmancer.txt` (liste Draftmancer) et `scores.py` (note et explication de chaque carte).
2. `make images` puis `make data`.
3. Déclarer `assets/sets/<id>/` et `assets/sets/<id>/cards/` dans `pubspec.yaml`.

Le set apparaît alors dans le sélecteur, en touchant le nom du set dans l'en-tête.

## Déploiement web

Chaque push sur `main` publie la version web sur GitHub Pages (`.github/workflows/deploy-web.yml`) :
https://devmeup-fr.github.io/dracailles_p1p1/
