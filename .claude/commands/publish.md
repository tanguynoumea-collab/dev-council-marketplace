---
description: >-
  Publie ce repo (marketplace dev-team-council) sur GitHub : détecte ton pseudo, remplace les
  placeholders, init git + commit, puis crée le dépôt et pousse. Demande une confirmation
  explicite AVANT toute publication publique.
argument-hint: "[nom-du-repo, défaut : dev-council-marketplace]"
---

# Publier la marketplace dev-team-council sur GitHub

Tu publies ce repo sur le GitHub de l'utilisateur. **La création du dépôt est une action
irréversible de publication : tu DOIS obtenir un « oui » explicite de l'utilisateur avant de la
lancer.** Procède dans l'ordre, en t'arrêtant à la moindre anomalie.

## Étape 1 — Pré-vérifications (lecture seule)

1. Vérifie que GitHub CLI est présent et authentifié : `gh auth status`.
   - Si `gh` est absent ou non authentifié → **arrête-toi** et explique : soit installer/auth `gh`
     (`gh auth login`), soit publier manuellement (créer le repo sur github.com puis
     `git remote add origin … && git push -u origin main`). Ne tente rien d'autre.
2. Récupère l'identité GitHub :
   - pseudo : `gh api user --jq .login`
   - nom affiché : `gh api user --jq .name` (s'il est vide, réutilise le pseudo).
3. Détermine le nom du repo : premier mot de `$ARGUMENTS`, sinon `dev-council-marketplace`.
4. Confirme qu'on est bien à la racine du repo (présence de `.claude-plugin/marketplace.json` et du
   dossier `dev-team-council/`). Sinon, arrête-toi.

## Étape 2 — Remplacer les placeholders

Dans `README.md`, `.claude-plugin/marketplace.json` et `dev-team-council/.claude-plugin/plugin.json` :
- remplace toutes les occurrences de `<TON-PSEUDO-GITHUB>` par le pseudo détecté ;
- remplace toutes les occurrences de `<ton-nom-ou-pseudo>` par le nom affiché (ou le pseudo).

Puis **vérifie qu'il ne reste aucun placeholder** : `grep -rn '<TON-PSEUDO-GITHUB>\|<ton-nom-ou-pseudo>' .`
Si quelque chose subsiste, corrige avant de continuer. Re-valide les deux JSON (`python3 -c "import json,sys; json.load(open(sys.argv[1]))" <fichier>`).

## Étape 3 — Préparer le commit (local, réversible)

```
git init            # si pas déjà un repo
git add .
git commit -m "dev-team-council v0.1.0 — audit multi-rôles + correction pilotée"
git branch -M main
```

## Étape 4 — CONFIRMATION avant publication (obstacle obligatoire)

Affiche un récapitulatif clair et **demande un OUI explicite** avant de continuer :
- nom du dépôt : `<pseudo>/<nom-repo>`
- visibilité : **public** (nécessaire pour que des tiers puissent l'ajouter) — propose `--private`
  comme alternative si l'utilisateur préfère un usage strictement personnel ;
- rappel : un repo **public** rend tout le contenu (y compris ta méthode d'audit) visible de tous.

N'exécute l'étape 5 que si l'utilisateur répond clairement oui. S'il choisit privé, adapte le flag.

## Étape 5 — Créer le dépôt et pousser

```
gh repo create <nom-repo> --public --source=. --remote=origin --push
```
(remplace `--public` par `--private` si demandé.)

## Étape 6 — Restituer les commandes d'installation

Une fois poussé, affiche à l'utilisateur les deux commandes que des tiers utiliseront, avec le vrai
pseudo substitué :

```
/plugin marketplace add <pseudo>/<nom-repo>
/plugin install dev-team-council@dev-council-marketplace
```

Et rappelle que pour mettre à jour le contenu plus tard : modifier les fichiers, puis
`git add . && git commit && git push`.
