---
description: >-
  Audit complet dev-team-council — tous les tiers (1, 2, 3) + spécialistes conditionnels détectés,
  avec filtre sceptique, matrice de cross-challenge et arbitrage council. Produit un rapport
  persistant priorisé. Plus lourd que /dev-council-pilote ; à réserver aux audits approfondis.
argument-hint: "[chemin de la solution, optionnel — défaut : répertoire courant]"
---

# Audit complet — dev-team-council

Tu orchestres un **audit complet** de la solution .NET desktop dans `$ARGUMENTS` (ou le répertoire
courant). Tu appliques la **constitution du council** intégralement
(barème §4, schéma §7, anti-biais §6, rapport §8, transitions §11). **Lecture seule.**

## Étape 1 — Détection du roster complet

Lis les `.csproj` / `.sln` :
- **Noyau permanent** : Tier 1 (`architecte`, `mainteneur`, `tests`), Tier 2 (`fiabilite`,
  `securite`, `donnees`), Tier 3 (`packaging`, `pertinence`).
- **Spécialistes conditionnels** : ajoute `autodesk` si `RevitAPI.dll`/`RevitAPIUI.dll` ou `.addin`
  détecté. (Tier 3 `packaging`/`pertinence` : calibre selon que le projet est distribué ou jetable.)
- Annonce le roster retenu.

## Étape 2 — Dispatch parallèle des auditeurs

Lance tous les agents retenus en contexte isolé. Chacun : Phase 1 (outils) → Phase 2 (jugement) →
findings au format §7 + relevé « non vérifié faute d'outil ». Tu collectes, tu ne corriges pas.

## Étape 3 — Filtre anti-inflation (`sceptique`)

Lance `sceptique` sur tous les findings. Il renseigne `Statut challenge` (validé / sévérité abaissée
/ invalidé / en arbitrage). Les invalidés sortent du plan (annexe « écartés » + raison).

## Étape 4 — Matrice de cross-challenge (§6.2 — paires fixes, PAS all-vs-all)

Pour chaque paire, l'agent challenge l'autre **uniquement sur leur intersection**, jamais sur tout
son domaine :
- **Architecte ↔ Sécurité** : un choix d'archi a-t-il une implication sécu (ex. stockage des secrets) ?
- **Architecte ↔ Tests** : le découpage rend-il le code testable ?
- **Fiabilité ↔ Données** : transactions / intégrité sous erreur.
- **Sécurité ↔ Données** : parsing / injection sur données persistées.
Un cross-challenge peut ajouter un angle à un finding existant ou en faire émerger un sur
l'intersection. Reste borné aux paires ci-dessus.

## Étape 5 — Arbitrage council (§6.3 — seulement sur les findings « en arbitrage »)

Pour les findings que le sceptique a marqués `en arbitrage council` (trade-offs débattus, ex.
« refactor maintenant vs ship acceptable ») : obtiens **2-3 jugements indépendants en aveugle**,
classe-les, et tranche par la position la mieux argumentée. C'est le seul endroit où le mécanisme
council d'origine s'applique — parce que c'est une question unique à vraie réponse.

## Étape 6 — Synthèse → rapport persistant (§8)

Écris `audits/dev-council-<AAAA-MM-JJ>.md` en trois couches : (1) verdict + résumé exécutif + points
non vérifiés ; (2) plan de remédiation priorisé (sévérité × tier, regroupé par fichier/module) ;
(3) findings détaillés au format §7, IDs stables, statut de challenge visible. Dédoublonne et
recoupe entre agents.

## Étape 7 — Transition conditionnelle (§11 — seulement si pertinent)

Comme `/dev-council-pilote` étape 5 : propose `/dev-council-fix` si Bloquants/Majeurs ; signale sans
urgence si seulement Mineur/Info ; pointe le guide d'install si couverture aveugle ; **silence** si
rien. Présente le chemin du rapport à la fin.
