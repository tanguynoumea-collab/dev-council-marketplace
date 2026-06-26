---
description: >-
  Applique les corrections du dernier rapport dev-team-council via l'agent correcteur : cycle
  atomique, portail à 4 portes, revert automatique, lot groupé pour les corrections sensibles.
  Seule commande du council qui écrit dans le code.
argument-hint: "[chemin du rapport, optionnel — défaut : dernier audits/dev-council-*.md]"
---

# Correction pilotée — dev-team-council

Tu lances l'agent **`correcteur`** sur le rapport d'audit (`$ARGUMENTS`, ou le dernier
`audits/dev-council-*.md` par défaut). Tu appliques la constitution §10.

## Pré-vol (conditions de sûreté)

Avant de lancer le correcteur, vérifie :
1. **Repo sous git et arbre propre** : la réversibilité unitaire en dépend. Si non sous git, ou
   modifications non commitées en cours → **arrête-toi et demande** de committer/stasher d'abord.
2. **Un rapport existe** : sinon, suggère de lancer `/dev-council-pilote` ou `/dev-council` d'abord.

## Lancement

Invoque `correcteur`. Il : classe chaque finding (mécanique / conception / sensible), auto-applique
le mécanique dans la boucle atomique à 4 portes (compile par target, tests verts, finding fermé
prouvé, aucun nouveau finding ; sinon revert), et **regroupe** conception + sensible pour validation
en fin de course (mode groupé, sans interrompre la boucle).

## Sortie

Le correcteur écrit `audits/dev-council-fix-<date>.md` (corrigé / annulé / en attente de décision).

## Transition conditionnelle (§11)

- Des fix appliqués → propose la re-vérification ciblée : `/dev-council-role <rôle>` sur les
  domaines touchés, pour confirmer la fermeture.
- Un **lot groupé en attente** → c'est la transition : présente-le et demande la validation groupée.
- Des fix annulés (porte échouée) → liste les findings repassés en intervention manuelle.

Rappelle la limite : le mécanique est auto-appliqué sous garanties ; le structurel et le sensible
attendent ta décision.
