---
description: >-
  Audit pilote dev-team-council — Tier 1 uniquement (Architecte, Mainteneur, Tests) + spécialiste
  Autodesk si le projet référence RevitAPI.dll. Mode rapide pour le projet cobaye et la
  calibration. Produit un rapport persistant priorisé.
argument-hint: "[chemin de la solution, optionnel — défaut : répertoire courant]"
---

# Audit pilote — dev-team-council (Tier 1)

Tu orchestres un **audit pilote** de la solution .NET desktop située dans `$ARGUMENTS`
(ou le répertoire courant si vide). Tu appliques la **constitution du council**
(barème §4, schéma de finding §7, format de rapport §8, transitions §11). Tu ne modifies aucun
fichier (audit = lecture seule).

## Étape 1 — Détection du roster

Lis les `.csproj` et le `.sln` :
- Confirme la cible (desktop .NET) et les targets/frameworks.
- **Active toujours** : `architecte`, `mainteneur`, `tests` (Tier 1).
- **Active `autodesk` SI ET SEULEMENT SI** un `.csproj` référence `RevitAPI.dll` /
  `RevitAPIUI.dll`, ou qu'un manifest `.addin` est présent. Sinon, n'invoque pas cet agent.
- Annonce le roster retenu avant de lancer.

## Étape 2 — Dispatch parallèle des auditeurs

Lance les subagents retenus, **chacun dans son contexte isolé** :
- `architecte`, `mainteneur`, `tests` (+ `autodesk` si détecté).
- Chaque agent exécute sa Phase 1 (outils) puis Phase 2 (jugement), et rend ses findings au
  format §7 avec son relevé « non vérifié faute d'outil ».
- Tu ne corriges rien, tu collectes.

## Étape 3 — Filtre anti-inflation (agent `sceptique`)

Lance l'agent `sceptique` sur l'ensemble des findings collectés. Il tente d'invalider chacun
(réel ou style ? exploitable ou théorique ? applicable desktop ou réflexe web ?) et renseigne le
champ `Statut challenge` : validé / sévérité abaissée / invalidé / en arbitrage council. Les
findings invalidés sortent du plan de remédiation (conservés en annexe « écartés » avec leur
raison). La règle de preuve reste le plancher : tout finding sans champ Preuve est de toute façon
dégradé en `Info`.

## Étape 4 — Synthèse → rapport persistant

Écris un fichier `audits/dev-council-<AAAA-MM-JJ>.md` dans la solution, structuré en **trois
couches** (§8) :

1. **Verdict + résumé exécutif** : compte par sévérité, verdict global (ex. « 2 Bloquants → non
   livrable »), et la **liste explicite des points non vérifiés faute d'outil**.
2. **Plan de remédiation priorisé** : liste ordonnée de ce qu'il faut corriger d'abord
   (sévérité × tier — un finding Tier 1 prime à sévérité égale), **regroupée par fichier/module**
   quand des corrections se touchent. Chaque entrée référence les IDs.
3. **Findings détaillés** : chaque finding au format §7, groupé par sévérité, ID stable, statut de
   challenge visible.

Dédoublonne et recoupe les findings entre agents avant d'écrire.

## Étape 5 — Transition conditionnelle (§11 — seulement si pertinent)

Après avoir écrit le rapport, propose l'étape suivante **uniquement si elle a du sens** :
- Bloquants/Majeurs présents → « Plan de remédiation : N corrections, dont X mécaniques
  auto-applicables. Lancer `/dev-council-fix` ? » *(note : `/dev-council-fix` et `correcteur.md`
  doivent exister pour que ce soit opérationnel.)*
- Que du Mineur/Info → signale-le sans fausse urgence ; mentionne l'option d'élargir au Tier 2
  avec `/dev-council`.
- Points non vérifiés faute d'outil → pointe vers le guide d'installation pour débloquer la
  couverture aveugle.
- Aucun finding → confirmation brève, **aucune** suggestion.

Présente le chemin du rapport à la fin.
