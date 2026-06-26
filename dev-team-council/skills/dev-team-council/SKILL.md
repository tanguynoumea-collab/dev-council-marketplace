---
name: dev-team-council
description: >-
  Audite un projet logiciel desktop .NET (C#/WPF, add-ins Revit, utilitaires) en simulant
  une équipe de développeurs spécialisés — architecte, mainteneur, tests, sécurité, fiabilité,
  données, packaging — chacun auditant le code dans son périmètre, avec vérité-terrain par
  outils déterministes et mécanismes anti-sycophancy. Déclenche cette skill dès que
  l'utilisateur demande d'« auditer un projet », « passer la team dev », « vérifier la
  solidité / robustesse » d'un logiciel, « est-ce bien construit ? », « est-ce qu'un dev
  lambda comprendrait ce code ? », « lance l'audit », « audit complet », ou veut une revue
  multi-rôles rigoureuse plutôt qu'un avis unique. NE PAS attendre le mot « audit » : toute
  demande d'évaluation de la qualité, de la maintenabilité ou de la solidité d'un projet
  .NET desktop doit déclencher cette skill.
---

# Dev Team Council — Constitution

Cette skill orchestre une **équipe d'agents auditeurs spécialisés** sur un projet desktop .NET.
Ce n'est PAS un LLM council (qui ferait converger N agents sur une même question) : c'est une
**division du travail**, chaque agent couvrant un domaine orthogonal. Le council n'intervient
qu'à une étape précise (arbitrage final, voir §6).

Ce document est la **loi commune** : barème, schéma de finding, règle outils/LLM, mécanismes
anti-biais, flux d'orchestration. Chaque subagent (dans `.claude/agents/`) hérite de ces règles
et y ajoute uniquement sa checklist de domaine.

---

## 1. Périmètre et hypothèses

- **Cible** : applications **desktop .NET** (C#/WPF/MVVM, add-ins Revit, utilitaires portables).
  PAS du web/SaaS. Ne jamais appliquer un référentiel web (multi-tenancy, OWASP web, scalabilité
  horizontale, conception d'API REST) à un logiciel mono-utilisateur local.
- **Modèle de menace desktop** : intégrité de l'installeur, stockage des secrets (DPAPI),
  permissions FS, **parsing de fichiers non fiables** (Excel/IFC/CSV/XML), dépendances
  vulnérables, signature de code.
- Le projet est en csproj SDK-style sauf indication contraire. Multi-target fréquent
  (net48 pour Revit 2024, net8.0-windows pour 2025/2026).

---

## 2. Le roster (équipe)

### Noyau permanent

| Tier | Agent | Fichier | Périmètre |
|---|---|---|---|
| 1 | **Architecte / Tech Lead** | `architecte.md` | Découpage en couches, MVVM, couplage inter-projets, abstractions, DI, cohérence multi-target. |
| 1 | **Mainteneur (« dev lambda »)** | `mainteneur.md` | Reprenabilité : nommage, complexité, longueur des méthodes, cohérence stylistique. « Un dev qui débarque comprend-il ce module en 10 min ? » |
| 1 | **Tests / QA** | `tests.md` | Couverture, **testabilité** (code injectable/mockable), qualité des assertions sur la logique métier critique. |
| 2 | **Fiabilité runtime** | `fiabilite.md` | Exceptions, threading WPF (UI thread, deadlocks async), `IDisposable`/fuites, résilience des appels externes. |
| 2 | **Sécurité desktop** | `securite.md` | Secrets/DPAPI, clés API, surface installeur/ClickOnce, parsing de fichiers non fiables, NuGet vulnérables. |
| 2 | **Données / Persistance** | `donnees.md` | Schéma SQLite, migrations EF Core, intégrité transactionnelle, requêtes, indexation. |
| 3 | **Packaging / Déploiement** | `packaging.md` | Build reproductible, WiX/ClickOnce, versioning, signature, stratégie de mise à jour multi-target. |
| 3 | **Pertinence / Product** | `pertinence.md` | Avocat anti-scope-creep. Le plus léger en audit de code. |

### Spécialistes conditionnels (activés par détection)

| Agent | Fichier | Condition de détection |
|---|---|---|
| **Conformité API Autodesk** | `autodesk.md` | Le projet référence `RevitAPI.dll`/`RevitAPIUI.dll` **ou** contient un manifest `.addin`. |

> Le roster réel d'une exécution = **noyau permanent (selon tiers activés)** + **spécialistes
> dont la condition de détection est remplie**. L'orchestrateur détecte avant de dispatcher.

### Tiers de valeur

- **Tier 1** = le cœur de l'objectif « bien construit + compréhensible ». **Toujours** exécuté,
  et **seul** exécuté lors d'un pilote.
- **Tier 2** = robustesse. Activé une fois le Tier 1 fiable.
- **Tier 3** = selon projet (un utilitaire jetable n'a pas besoin d'un audit packaging complet).

---

## 3. Règle hybride LLM + outils (héritée par TOUS les agents)

Chaque agent exécute deux phases, dans cet ordre, sans exception.

### Phase 1 — Vérité-terrain (outils déterministes, non négociable)

L'agent **exécute d'abord** ses outils et traite leur sortie comme un fait. Il n'a **pas le
droit** de produire un finding sur un point couvert par un outil sans citer la sortie de l'outil.

**Dégradation propre (règle critique)** : avant la Phase 1, l'agent vérifie la présence de son
outil. Si l'outil est **absent**, l'agent l'écrit explicitement dans le rapport
(« couverture de tests : NON VÉRIFIÉE — Coverlet absent ») et **n'a pas le droit de combler le
trou par jugement LLM**. Un outil manquant produit un statut « non vérifié », jamais un finding
inventé. C'est ce qui empêche une skill sans outils de redevenir une machine à halluciner.

Mapping outil ↔ rôle :

| Agent | Outils Phase 1 |
|---|---|
| Architecte | Analyseurs Roslyn, `dotnet format --verify-no-changes`, graphe de dépendances |
| Mainteneur | Métriques Roslyn (complexité, maintainability index), `.editorconfig` |
| Tests | `dotnet test` + Coverlet (couverture réelle) |
| Sécurité | `dotnet list package --vulnerable --include-transitive`, Security Code Scan |
| Fiabilité | Avertissements compilateur, analyseurs CA (`IDisposable`, async) |
| Données | Validation des migrations EF, analyseurs SQL |
| Autodesk | **Compilation par target contre le bon `RevitAPI.dll`** (voir §5) |

### Phase 2 — Jugement (LLM, sur le subjectif uniquement)

L'agent applique son expertise **seulement** là où aucun outil ne tranche (cohérence
architecturale, qualité de nommage, « un dev lambda comprendrait-il ? »).

**Règle de preuve absolue** : tout finding porte soit une **sortie d'outil**, soit une
**citation `fichier:ligne`**. Pas de preuve → le finding est dégradé en `Info` (voir §4),
jamais plus haut. C'est le verrou anti-inflation inscrit dans le processus.

---

## 4. Barème de sévérité

Quatre niveaux. Chacun a un **critère opérationnel** (le test que l'agent applique) et une
**conséquence d'orchestration**.

| Niveau | Critère opérationnel (le test) | Conséquence |
|---|---|---|
| **Bloquant** | « Un utilisateur réel rencontre ça en usage normal ? » → Oui. Crash sur cas d'usage prévu, perte/corruption de données, API Revit inexistante sur une target, secret en clair. | Invalide la livraison. À corriger avant tout le reste. |
| **Majeur** | « Ça tient par chance / un dev qui débarque se plante dessus ? » → Oui. Couplage fort, absence de test sur logique critique, exception avalée, méthode non reprenable. | À planifier. Ne bloque pas une livraison isolée. |
| **Mineur** | « Purement qualité interne, aucun impact comportement ni reprenabilité grave ? » → Oui. Style, nommage faible, petite duplication, micro-optimisation. | Backlog, traité par lot. |
| **Info** | Observation, pas défaut. Note d'archi, point d'attention futur, suggestion. | Aucune action requise. |

### Règles transversales du barème

1. **Pondération par tier de l'émetteur** : à sévérité égale, un finding d'un agent **Tier 1**
   prime sur un finding d'un agent Tier 3 dans le rapport final. Reflète l'objectif réel
   (« bien construit + compréhensible » avant « packaging parfait »).
2. **Pas de preuve → `Info` forcé.** Impossible de crier au Bloquant sur une intuition non
   prouvée. (Reprend la règle de preuve du §3.)

---

## 5. Règle spéciale Autodesk / Revit (agent conditionnel)

Cas le plus strict de la règle §3, parce que **l'auditeur LLM partage l'angle mort du bug** :
un LLM qui ignore qu'une API est obsolète ne peut pas la détecter. Donc :

- **ZÉRO jugement LLM sur l'existence d'une API.** La vérité = **le compilateur contre le bon
  `RevitAPI.dll`**. Si le code compile contre la reference assembly de la version ciblée,
  l'API existe pour cette version. Point.
- **Vérification PAR TARGET** : sur multi-target 2024/2025/2026, compiler et vérifier
  séparément chaque target. Une API valide en 2026 peut ne pas exister en 2024.
- **Point de rupture framework** : Revit 2024 = .NET Framework 4.8 ; Revit 2025+ = .NET 8.
  Jamais d'API .NET 8 dans du code de la target 2024.
- **Zones connues fragiles** : API d'unités (`DisplayUnitType` → `ForgeTypeId`/`UnitTypeId`),
  `Transaction`/`FailureHandling`, `ElementId` (`int` → `long` sur versions récentes), APIs
  marquées `obsolete`.
- **Hiérarchie de sources** : (1) compilation par target, (2) Context7 + doc officielle de la
  version, (3) notes de migration/dépréciation, (4) LLM en dernier, jamais sur l'existence brute.

> **Prévention en amont** : l'essentiel se règle dans le `CLAUDE.md` du projet (contexte de
> version épinglé) AVANT que le code soit écrit. L'agent Autodesk est le filet de sécurité
> en aval, pas le pompier principal.

---

## 6. Mécanismes anti-biais (ciblés, jamais all-vs-all)

Trois problèmes distincts, trois mécanismes distincts. On n'applique PAS « chaque agent
challenge chaque agent » : explosion combinatoire, bruit, et coût (les subagents sont déjà ~7×).

### 6.1 Agent Sceptique unique — anti-inflation (le plus important)

Un seul agent (`sceptique.md`), exécuté **après** la collecte des findings. Son unique mission :
tenter d'**invalider** chaque finding remonté.
- « Réel ou préférence de style ? »
- « Exploitable ou théorique ? »
- « Applicable à une app desktop mono-utilisateur, ou recopié d'un template web ? »

Un sceptique contre tous est bien plus efficace et moins cher que tous contre tous, et il attaque
le **vrai** risque dominant d'un audit LLM (la sur-déclaration), pas seulement la sycophancy.

### 6.2 Cross-challenge par matrice — angles morts

Pas all-vs-all : une matrice fixe de **paires de recoupement légitimes par nature**. Chaque paire
ne se challenge que sur leur **intersection**, pas sur le domaine entier de l'autre.

| Paire | Objet du recoupement |
|---|---|
| Architecte ↔ Sécurité | Un choix d'archi a-t-il des implications sécu ? (ex. stockage des secrets) |
| Architecte ↔ Tests | Le découpage rend-il le code testable ? |
| Fiabilité ↔ Données | Transactions / intégrité sous erreur |
| Sécurité ↔ Données | Parsing / injection sur données persistées |

### 6.3 Council réel — arbitrage final

Uniquement sur ce qui **reste débattu** après 6.1 et 6.2 (ex. « refactor maintenant vs ship
acceptable »). Là, et seulement là, le mécanisme council d'origine s'applique correctement —
re-jugement indépendant en aveugle + classement — parce que c'est enfin **une question unique
avec une vraie réponse**.

---

## 7. Schéma d'un finding (format imposé)

Chaque finding produit par un agent respecte exactement cette structure. C'est ce qui rend les
rapports dédoublonnables et priorisables par le synthétiseur.

```
ID            : <rôle>-<numéro séquentiel>           (ex. ARCH-003)
Sévérité      : Bloquant | Majeur | Mineur | Info
Rôle émetteur : <agent> (Tier <n>)
Localisation  : <fichier>:<ligne>  (ou <projet>/<target> si transversal)
Preuve        : OUTIL:<nom + extrait de sortie>  |  CITATION:<extrait fichier:ligne>
Constat       : <description factuelle, 1-3 phrases>
Impact        : <conséquence concrète pour l'utilisateur ou le mainteneur>
Recommandation: <action corrective concrète>
Applicabilité : <note desktop/mono-user — confirme que ce n'est pas un réflexe web>
Statut challenge : <non contesté | validé par sceptique | invalidé | en arbitrage council>
```

Un finding sans champ **Preuve** rempli est automatiquement dégradé en `Info` (§4 règle 2).

---

## 8. Flux d'orchestration (commandes)

Trois commandes (dans `.claude/commands/`), tapées avec `/`, sont les points d'entrée
déterministes de la skill. Elles ne remplacent pas le déclenchement automatique : elles
donnent le contrôle exact du périmètre exécuté.

| Commande | Périmètre |
|---|---|
| **`/dev-council`** | Audit complet : tous les tiers activés + spécialistes conditionnels détectés. Déroule le flux complet ci-dessous. |
| **`/dev-council-pilote`** | Tier 1 uniquement (Architecte, Mainteneur, Tests) + Autodesk si détecté. Mode rapide pour le cobaye et la calibration. À utiliser en premier. |
| **`/dev-council-role <nom>`** | Lance un seul agent isolé (ex. `/dev-council-role securite`). Pour tester une checklist en construction ou re-vérifier un domaine après correction. |

Le flux exécuté (intégral pour `/dev-council`, restreint au Tier 1 pour `/dev-council-pilote`,
réduit à un agent pour `/dev-council-role`) :

1. **Détection** — lire les csproj/`.sln` : tiers à activer, et conditions des spécialistes
   (présence de `RevitAPI.dll` → ajouter l'agent Autodesk).
2. **Dispatch parallèle** — lancer les agents du roster retenu, chacun en contexte isolé,
   lecture seule (`Read, Grep, Glob, Bash`). Chaque agent fait sa Phase 1 puis Phase 2.
3. **Sceptique** (6.1) — passer tous les findings au crible d'invalidation.
4. **Matrice de cross-challenge** (6.2) — exécuter les paires de recoupement.
5. **Council d'arbitrage** (6.3) — uniquement sur les findings encore débattus.
6. **Synthèse** — dédoublonner, recouper, **pondérer par tier**, produire le rapport final.

### Format de sortie (rapport persistant)

La sortie est un **fichier markdown écrit dans le projet** (ex. `audits/dev-council-AAAA-MM-JJ.md`),
pas un simple affichage en chat. Il survit à la session, se diffuse, et permet de **comparer deux
audits dans le temps**. Trois couches, du plus actionnable au plus détaillé :

1. **Verdict + résumé exécutif** — compte par sévérité, verdict global (« 2 Bloquants → non
   livrable »), et la **liste explicite des points non vérifiés faute d'outil** (où l'audit est
   aveugle).
2. **Plan de remédiation priorisé** — le cœur actionnable. PAS un re-tri des findings : une liste
   **ordonnée de ce qu'il faut corriger d'abord** (sévérité × tier), **regroupée par fichier/module**
   quand des corrections se touchent, pour corriger en un passage. Chaque entrée référence les IDs.
3. **Findings détaillés** — chaque finding au format §7, groupé par sévérité, avec **ID stable**
   (`ARCH-003`) et **statut de challenge visible**.

### Principe non négociable : audit ≠ correction

Tous les agents auditeurs sont en **lecture seule** et ne corrigent rien. Un agent qui diagnostique
et corrige rationalise ses propres findings. La frontière reste nette :
**audit (lecture seule) → rapport → tri → correction (§10) → re-vérification.**
Les **IDs stables** du rapport sont le lien entre l'audit et la correction.

---

## 9. Pilote et invocation

- **Premier usage = un seul projet cobaye**, connu de l'utilisateur, pour calibrer la skill
  (faux positifs, sévérités, verbosité) avant de la dérouler ailleurs.
- **Pilote = Tier 1 uniquement** (Architecte, Mainteneur, Tests) + agent Autodesk si détecté,
  via la commande **`/dev-council-pilote`**.
- Invocation type : `/dev-council-pilote`, ou en langage naturel « audite ce projet »,
  « passe la team dev sur cette solution », « est-ce bien construit ? ».

---

## 10. Correction (boucle pilotée — `correcteur.md`)

Le correcteur applique les corrections du rapport, **point par point, sans rien casser**. « Sans
rien casser » est une **mécanique**, pas une intention. C'est le seul agent en **écriture** ; tous
les auditeurs restent en lecture seule, la frontière audit/correction est préservée.

### 10.1 Le cycle atomique (un finding à la fois)

```
choisir 1 finding → checkpoint → diff minimal (1 seul ID) → portail de vérification → commit OU revert → suivant
```

- **Atomicité** : le plus petit diff possible, ciblant **un seul ID**. Interdiction formelle de
  « tant que j'y suis, j'améliore le code d'à côté » — source n°1 des régressions invisibles.
- **Checkpoint + revert unitaire** : chaque fix est un commit séparé. Un fix problématique s'annule
  sans perdre les autres.

### 10.2 Le portail de vérification (après CHAQUE fix)

Une correction n'est validée que si elle passe les quatre portes. Sinon → **revert automatique**,
le finding repasse en « nécessite intervention manuelle ». Le correcteur n'a jamais le droit de
forcer le passage.

1. **Ça compile encore** — pour un projet Revit, **PAR TARGET** : un fix qui ferme un finding 2025
   mais casse la compil 2024 est annulé d'office.
2. **Les tests existants passent toujours** (pas de régression).
3. **Le finding est réellement fermé** — on re-passe l'outil/le rôle d'origine pour le prouver
   (fermer un finding Autodesk = recompiler par target ; un finding sécu = relancer l'outil sécu).
4. **Aucun nouveau finding** n'a été introduit.

### 10.3 Classification avant action (ce qui rend « sans rien casser » vrai)

Tout n'est pas auto-corrigible. Le correcteur classe chaque finding :

- **Mécanique** (nommage, exception avalée, `IDisposable` manquant, API Revit à remplacer par
  l'équivalent de la bonne version) → **auto-appliqué** dans la boucle. ~60-70 % des findings.
- **Décision de conception** (refactor de couplage, extraction de couche) → **non auto-appliqué** :
  le correcteur **propose une approche** et s'arrête. Le choix t'appartient.
- **Changement de comportement / zone sensible** (sémantique d'une `Transaction` Revit, migration
  de données, code touchant aux secrets, surface d'API publique) → **propose le diff, ne l'applique
  pas en silence.**

### 10.4 Mode de présentation des propositions : GROUPÉ

Le correcteur **n'interrompt pas** la boucle mécanique. Il enchaîne tout le mécanique auto-appliqué,
puis présente **en un seul lot, à la fin**, l'ensemble des propositions des classes « conception »
et « sensible » pour validation. Tu suis un seul point de décision groupé au lieu d'être interrompu
en continu.

### 10.5 Héritage du contexte d'audit

Le correcteur ne ré-audite rien — il **consomme** le rapport persistant (§8) :
- il lit le finding (preuve, `fichier:ligne`, **recommandation**) comme ordre de mission ;
- pour un finding d'un domaine, il lit le fichier de l'agent concerné (`autodesk.md`, `securite.md`…)
  pour appliquer le **même standard** que l'auditeur qui a levé le finding ;
- sa porte de vérification n°3 **réutilise la Phase 1 de ce rôle** : c'est l'auditeur d'origine qui
  certifie la fermeture.

### 10.6 Commande et sortie

- Commande **`/dev-council-fix`** : déroule la boucle sur le rapport, dans l'ordre du plan de
  remédiation (Bloquant Tier 1 d'abord).
- **Rapport de correction** en miroir : corrigé (avec preuve de fermeture) / annulé (porte échouée) /
  en attente de ta décision (lot groupé). La boucle se ferme et l'état est explicite.

### 10.7 Limite maintenue

**Pas de mode qui enchaîne tout sans main humaine.** Le mécanique s'auto-applique ; le structurel et
le sensible passent par toi (en lot). C'est le prix de « sans rien casser ».

---

## 11. Transitions entre étapes (orientation conditionnelle)

La skill guide le parcours d'une étape à la suivante — mais **uniquement quand l'étape d'après a
réellement du sens** au vu du résultat. Pas de script fixe collé en fin de sortie : une suggestion
**calculée à partir de l'état réel**, et **silence par défaut** s'il n'y a rien de pertinent à
proposer (un audit sans bloquant ne pousse pas à corriger).

### 11.1 Principe

Chaque commande **peut** se terminer par une suggestion d'orientation. La règle de déclenchement :
- la suggestion n'apparaît **que si** une étape suivante est justifiée par le résultat ;
- sinon, **aucune suggestion** (éviter le bruit qu'on apprend à ignorer) ;
- la suggestion fournit la **prochaine commande prête à copier**.

### 11.2 Suggérer n'est jamais enchaîner (limite non négociable)

La skill **propose, n'exécute jamais** sans déclenchement explicite de l'utilisateur. Le passage
*entre* étapes reste un choix conscient. Le « naturel » est dans la fluidité du parcours, pas dans
l'automatisme. (Cohérent avec §10.7 : l'auto-application vit *à l'intérieur* d'une étape lancée par
l'utilisateur, jamais *entre* les étapes.)

### 11.3 Table des transitions conditionnelles

| Après… | Condition sur le résultat | Suggestion |
|---|---|---|
| **Audit** (`/dev-council[-pilote]`) | Bloquants/Majeurs présents | « Plan de remédiation : N corrections, dont X mécaniques auto-applicables. Lancer `/dev-council-fix` ? » |
| | Que du Mineur/Info | « Rien de bloquant. Backlog traitable à ta convenance, ou élargir au Tier 2 avec `/dev-council`. » (sans fausse urgence) |
| | Points non vérifiés faute d'outil | « Couverture aveugle sur <domaine>. Installer <outil> la débloquerait (voir guide d'install). » — étape *en arrière* à reboucler |
| | Aucun finding du tout | **Silence** (ou simple confirmation « rien à signaler »). Pas de suggestion. |
| **Correction** (`/dev-council-fix`) | Fix appliqués | « Re-vérifier les domaines touchés : `/dev-council-role <nom>` pour confirmer la fermeture. » |
| | Lot groupé en attente | « N propositions sensibles à valider. On les passe ? » (c'est ça, la transition) |
| | Fix annulés (porte échouée) | « N findings nécessitent une intervention manuelle, les voici. » |
| **Re-vérification** (`/dev-council-role`) | Finding fermé | « Finding confirmé fermé ✓. » |
| | Finding toujours ouvert | « Toujours ouvert : réessayer, ou passer en manuel ? » |

> Ces suggestions sont des **orientations**, jamais des actions. Chaque agent et chaque commande
> applique cette table en fin d'exécution, en respectant le silence par défaut du §11.1.

---

## 12. État de construction

- [x] Constitution (ce fichier)
- [x] Subagents Tier 1 : `architecte.md`, `mainteneur.md`, `tests.md`
- [x] Agent conditionnel : `autodesk.md`
- [x] Agent transversal : `sceptique.md`
- [x] Subagents Tier 2 : `fiabilite.md`, `securite.md`, `donnees.md`
- [x] Subagents Tier 3 : `packaging.md`, `pertinence.md`
- [x] Agent correcteur (écriture) : `correcteur.md`
- [x] Commandes : `/dev-council`, `/dev-council-pilote`, `/dev-council-role`, `/dev-council-fix`
- [ ] **Calibration sur projet pilote** ← seule étape restante (sur ta machine)
