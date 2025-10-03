#!/usr/bin/env bash
set -euo pipefail

WORKDIR="git-workshop"
if [ -d "$WORKDIR" ]; then
  echo "Le dossier '$WORKDIR' existe déjà. Supprime-le ou choisis un autre emplacement."
  exit 1
fi

mkdir "$WORKDIR"
cd "$WORKDIR"
git init

# Config locale pour éviter de dépendre de la config utilisateur
# git config user.name "Workshop Bot"
# git config user.email "bot@example.com"

############################################
# MAIN – Base du projet
############################################
echo "# Projet Git" > README.md
echo "App v1" > app.txt
cat > src.txt <<'EOF'
LINE_A=stable
LINE_B=todo
LINE_C=buggy
EOF

git add .
git commit -m "C1: Initial commit (main)"

# Petite release stable
echo "CHANGELOG" > CHANGELOG.md
echo "- v0.1: initial release" >> CHANGELOG.md
git add CHANGELOG.md
git commit -m "C2: Add CHANGELOG (main)"

############################################
# FEATURE-SUPER – Historique “sale”
############################################
git checkout -b feature-super

# wip peu clair
echo "fonction A" > a.txt
git add a.txt
git commit -m "wip"

# ajout flou
echo "fonction B" > b.txt
git add b.txt
git commit -m "ajout fichier"

# commit à conserver: corrige une ligne dans app.txt (sera cherry-pické)
# On corrige LINE_C=buggy -> LINE_C=fixed
sed -i.bak 's/LINE_C=buggy/LINE_C=fixed/' src.txt 2>/dev/null || true
rm -f src.txt.bak
git add src.txt
git commit -m "fix: correct LINE_C from buggy to fixed (critical)"

# message cryptique
echo "fonction C" > c.txt
git add c.txt
git commit -m "C3"

# déchet à supprimer lors du rebase -i
echo "tmp debug logs" > debug.log
git add debug.log
git commit -m "temp debug"

# encore un petit commit verbeux
echo "trace=1" >> a.txt
git add a.txt
git commit -m "misc: add trace flag"

# marqueur: le fix critique (facilite l'identification)
FIX_COMMIT_HASH=$(git rev-parse HEAD~2)
git tag -a FIX_CRITIQUE -m "Commit critique à cherry-pick" "$FIX_COMMIT_HASH"

############################################
# MAIN – Changements qui provoqueront un conflit au cherry-pick
############################################
git checkout main

# On modifie la même ligne que le fix critique… mais différemment.
# Le fix sur feature-super remplace LINE_C=buggy par LINE_C=fixed.
# Ici, on remplace LINE_C=buggy par LINE_C=stable_override -> conflit garanti.
sed -i.bak 's/LINE_C=buggy/LINE_C=stable_override/' src.txt 2>/dev/null || true
rm -f src.txt.bak
git add src.txt
git commit -m "C3: Change LINE_C to stable_override (main)"

# Ajout d'un fichier de release
echo "release=0.2" > release.cfg
git add release.cfg
git commit -m "C4: Prepare release 0.2 (main)"

############################################
# FEATURE-SUPER – Préparer plusieurs stashes
############################################
git checkout feature-super

# WIP 1 (non commit) -> stash 1
echo "WIP change 1" >> c.txt
echo "TMP_1=on" >> wip1.env
git add wip1.env
# On garde c.txt modifié NON stagé pour mélanger les états
git reset c.txt >/dev/null 2>&1 || true
git stash push -m "WIP-1 (partiellement stagé + untracked)" -u

# WIP 2 (non commit) -> stash 2
echo "WIP change 2" >> c.txt
echo "TMP_2=on" >> wip2.env
git add c.txt wip2.env
git stash push -m "WIP-2 (fichiers stagés)" -u

############################################
# HOTFIX branch – Contexte pour changer de branche en urgence
############################################
git checkout -b hotfix/urgent main
echo "urgent fix content" > hotfix.txt
git add hotfix.txt
git commit -m "HOTFIX: urgent fix on main branch context"

# On retourne sur feature-super pour que l'atelier restaure les bons stashes
git checkout feature-super

############################################
# MAIN – Commit qui casse la prod (à revert pendant l’atelier)
############################################
git checkout main
echo "BROKEN=1" > bug.txt
git add bug.txt
git commit -m "BREAK: Introduce a production bug (to be reverted)"

############################################
# MARQUEURS D’ATELIER (notes de contexte)
############################################
git checkout feature-super
cat > INSTRUCTIONS.txt <<'EOF'
Atelier Git Avancé (Énoncé)

Objectifs (à faire MANUELLEMENT) :
1) Sur feature-super : nettoyer l'historique via git rebase -i
   - Réordonner les commits
   - Fusionner (squash) les deux premiers commits “wip” et “ajout fichier”
   - Supprimer le commit “temp debug”
   - Renommer les messages trop vagues

2) Depuis main : cherry-pick du commit critique présent sur feature-super
   - Indice : tag FIX_CRITIQUE pointe dessus
   - Attends-toi à un CONFLIT sur src.txt (résoudre proprement)

3) Gestion de WIP : restaurer les stashes dans le bon ordre
   - Il existe au moins deux entrées dans git stash list
   - Choisir judicieusement entre pop/apply et gérer les untracked

4) Sur main : annuler proprement le commit qui casse la prod
   - Ne pas réécrire l’historique (utiliser git revert)

Résultat attendu :
- feature-super : historique propre et lisible
- main : correctif critique intégré sans merge complet
- WIPs : restaurés dans le bon ordre
- Prod : commit cassant annulé proprement

Ne modifiez pas le contenu de ce fichier pendant l’atelier.
EOF

git add INSTRUCTIONS.txt
git commit -m "Docs: add INSTRUCTIONS for the workshop"

echo
echo "✅ Dépôt prêt dans: $(pwd)"
echo "   Branches: main, feature-super, hotfix/urgent"
echo "   Un tag utile: FIX_CRITIQUE (commit à cherry-pick)"
echo
echo "   Suis les consignes dans INSTRUCTIONS.txt pour lancer l’atelier."
