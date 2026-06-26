---
description: >-
  Lance UN SEUL agent du council dev-team-council, isolé. Pour tester une checklist en construction
  ou re-vérifier un domaine après correction (ex. confirmer la fermeture d'un finding). Argument :
  le nom du rôle (architecte, mainteneur, tests, fiabilite, securite, donnees, packaging,
  pertinence, autodesk).
argument-hint: "<role> [chemin de la solution, optionnel]"
---

# Audit ciblé — un seul rôle

Tu lances **un seul agent** du council, dont le nom est le premier mot de `$ARGUMENTS` (le reste, le
chemin de solution optionnel ; défaut : répertoire courant).

## Étape 1 — Résoudre le rôle

Rôles valides : `architecte`, `mainteneur`, `tests`, `fiabilite`, `securite`, `donnees`,
`packaging`, `pertinence`, `autodesk`.
- Nom inconnu → liste les rôles valides et arrête-toi.
- `autodesk` demandé mais aucun `RevitAPI.dll`/`.addin` détecté → préviens que le spécialiste n'a
  pas lieu d'être ici, demande confirmation avant de lancer.

## Étape 2 — Lancer l'agent

Invoque le subagent correspondant en contexte isolé. Il exécute sa Phase 1 (outils) → Phase 2
(jugement) → findings au format §7 + relevé « non vérifié faute d'outil ». **Lecture seule.**

## Étape 3 — Restituer

Affiche les findings de l'agent au format §7. **Pas de sceptique, pas de matrice, pas de rapport
persistant** : cette commande est volontairement brute et ciblée (test / re-vérification rapide).

## Étape 4 — Cas « re-vérification après correction »

Si le contexte est une re-vérification (un finding précédemment corrigé), conclus clairement :
- **« Finding confirmé fermé ✓ »** si l'agent ne le retrouve plus ;
- **« Toujours ouvert »** s'il persiste → propose de réessayer une correction ou de passer en manuel.

C'est le seul cas où tu rends un verdict de transition (§11) ; sinon, aucune suggestion.
