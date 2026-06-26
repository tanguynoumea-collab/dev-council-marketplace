# dev-team-council (plugin)

Audit multi-rôles et correction pilotée pour projets **desktop .NET** (C#/WPF, add-ins Revit,
utilitaires). Installation : voir le README du repo (méthode plugin `/plugin install`, ou script).

## Ce que contient le plugin

```
dev-team-council/
├── .claude-plugin/plugin.json
├── skills/dev-team-council/SKILL.md   ← la constitution (loi commune)
├── agents/                            ← 11 subagents
│   ├── architecte.md  mainteneur.md  tests.md          (Tier 1)
│   ├── fiabilite.md   securite.md     donnees.md        (Tier 2)
│   ├── packaging.md   pertinence.md                     (Tier 3)
│   ├── autodesk.md                    (spécialiste conditionnel Revit)
│   ├── sceptique.md                   (transversal anti-inflation)
│   └── correcteur.md                  (écriture — correction)
└── commands/
    ├── dev-council.md          /dev-council        (audit complet)
    ├── dev-council-pilote.md   /dev-council-pilote (Tier 1 + Autodesk)
    ├── dev-council-role.md     /dev-council-role   (un agent isolé)
    └── dev-council-fix.md      /dev-council-fix    (correction)
```

## Cycle d'usage

1. `/dev-council-pilote` (ou `/dev-council`) → audit → rapport persistant priorisé dans `audits/`.
2. `/dev-council-fix` → correction mécanique auto (4 portes + revert), propositions sensibles
   groupées pour validation.
3. `/dev-council-role <rôle>` → re-vérification ciblée d'un domaine corrigé.

Les agents d'audit sont en **lecture seule** ; seul le correcteur écrit, et uniquement via
`/dev-council-fix`. Détails complets dans `skills/dev-team-council/SKILL.md`.
