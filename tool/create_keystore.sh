#!/usr/bin/env bash
# Crée la clé d'upload Google Play (android/p1p1_dracailles-keystore.jks)
# et android/key.properties, lu par android/app/build.gradle.kts.
# Les mots de passe sont saisis ici et ne sont écrits que dans key.properties (ignoré par git).
set -euo pipefail

cd "$(dirname "$0")/../android"
JKS=p1p1_dracailles-keystore.jks
ALIAS=upload

if [ -e "$JKS" ]; then
  echo "android/$JKS existe déjà : rien à faire (supprime-le d'abord si tu veux vraiment en recréer un)."
  exit 1
fi

read -r -s -p "Mot de passe du keystore (6 caractères min.) : " STORE_PASS; echo
read -r -s -p "Confirme le mot de passe : " STORE_PASS2; echo
[ "$STORE_PASS" = "$STORE_PASS2" ] || { echo "Les mots de passe ne correspondent pas."; exit 1; }
[ ${#STORE_PASS} -ge 6 ] || { echo "6 caractères minimum."; exit 1; }

keytool -genkeypair -v \
  -keystore "$JKS" -storetype JKS \
  -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$STORE_PASS" -keypass "$STORE_PASS" \
  -dname "CN=DevMeUp, O=DevMeUp, C=FR"

umask 077
cat > key.properties <<PROPS
storePassword=$STORE_PASS
keyPassword=$STORE_PASS
keyAlias=$ALIAS
storeFile=../$JKS
PROPS

echo
echo "OK : android/$JKS et android/key.properties créés."
echo "Sauvegarde le .jks et le mot de passe hors du dépôt : sans eux, plus de mise à jour possible sur le Play Store."
