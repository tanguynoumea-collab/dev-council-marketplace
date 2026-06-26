# dev-council-marketplace

Marketplace Claude Code hébergeant le plugin **dev-team-council** : un audit multi-rôles et une
correction pilotée pour projets **desktop .NET** (C#/WPF, add-ins Revit, utilitaires).

Une équipe d'agents auditeurs spécialisés (architecte, mainteneur, tests, sécurité, fiabilité,
données, packaging, conformité Autodesk), avec vérité-terrain par outils déterministes, mécanismes
anti-sycophancy, et un correcteur à portail de vérification à 4 portes.

---

## Installation (méthode recommandée — plugin)

Sur n'importe quelle machine disposant de Claude Code, **deux commandes** :

```
/plugin marketplace add tanguynoumea-collab/dev-council-marketplace
/plugin install dev-team-council@dev-council-marketplace
```

Redémarre Claude Code. Vérifie avec `/skills`, `/agents`, et tape `/dev-`. Les mises à jour se font
ensuite automatiquement (marketplace).

> Remplace `tanguynoumea-collab` par ton identifiant GitHub. Le repo doit être **public** pour que
> des tiers puissent l'ajouter (un repo privé ne fonctionne que pour toi / les comptes autorisés).

## Installation (alternative — script, sans plugin)

Si tu préfères copier les fichiers directement dans `~/.claude/` (utile en environnement où le
système de plugins n'est pas souhaité) :

```bash
# macOS / Linux
git clone https://github.com/tanguynoumea-collab/dev-council-marketplace && cd dev-council-marketplace && ./install.sh
```
```powershell
# Windows
git clone https://github.com/tanguynoumea-collab/dev-council-marketplace ; cd dev-council-marketplace ; ./install.ps1
```

Mise à jour : `git pull` puis relancer le script.

---

## ⚠️ Note de sécurité (à lire avant de distribuer / d'installer)

Ce plugin n'est pas passif :
- les agents **exécutent des commandes shell** (`dotnet build`, `dotnet test`, `git`, lecture de fichiers) ;
- le **correcteur écrit et commite du code** (uniquement via `/dev-council-fix`, derrière un pré-vol
  git et un portail de vérification à 4 portes avec revert automatique).

Tous les agents d'audit sont en **lecture seule** ; seul le correcteur écrit, et jamais sans ton
déclenchement explicite. Installe-le sur des dépôts que tu contrôles, et teste d'abord sur un projet
non critique.

## Pré-requis outils

Voir [`OUTILS-installation.md`](./OUTILS-installation.md). Le socle minimal (analyseurs Roslyn,
`.editorconfig`, `dotnet list package --vulnerable`, Coverlet) suffit. Sans outil, la skill tourne
quand même et signale « non vérifié faute d'outil ».

## Premier usage

```
/dev-council-pilote
```
sur un projet cobaye (idéalement un add-in référençant `RevitAPI.dll`, pour exercer le spécialiste
Autodesk). Calibre la skill sur ce projet connu avant de la dérouler ailleurs.

---

## Structure du repo

```
dev-council-marketplace/
├── .claude-plugin/
│   └── marketplace.json          ← catalogue (lu par /plugin marketplace add)
├── dev-team-council/             ← le plugin
│   ├── .claude-plugin/plugin.json
│   ├── skills/dev-team-council/SKILL.md   ← la constitution
│   ├── agents/   (11 agents)
│   ├── commands/ (4 commandes)
│   └── README.md
├── install.sh / install.ps1      ← installation par script (alternative)
├── OUTILS-installation.md
└── README.md
```

---

## Publier ce repo sur ton GitHub

**Méthode simple — la commande `/publish`.** Ouvre ce dossier dans Claude Code et tape :

```
/publish
```

Elle détecte ton pseudo GitHub, remplit les placeholders, fait le commit, **te demande
confirmation**, puis crée le dépôt et le pousse (via GitHub CLI `gh`). Pré-requis : `gh` installé et
authentifié (`gh auth login`).

**Méthode manuelle** (si tu préfères, ou si `gh` n'est pas dispo). Remplace d'abord les placeholders
`tanguynoumea-collab` et `DeDEL` dans `README.md`,
`.claude-plugin/marketplace.json` et `dev-team-council/.claude-plugin/plugin.json`, puis :

```bash
git init
git add .
git commit -m "dev-team-council v0.1.0 — audit multi-rôles + correction pilotée"
git branch -M main
gh repo create dev-council-marketplace --public --source=. --remote=origin --push
# OU, repo créé à la main sur github.com :
# git remote add origin https://github.com/tanguynoumea-collab/dev-council-marketplace.git
# git push -u origin main
```

Une fois poussé, l'installation tierce se résume aux deux commandes `/plugin` ci-dessus.
