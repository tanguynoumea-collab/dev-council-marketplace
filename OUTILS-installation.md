# Outils d'audit — Guide d'installation (projet add-in Revit multi-target)

Objectif : équiper le projet pilote des outils déterministes (Phase 1) que les agents
d'audit utiliseront comme **vérité-terrain**. Sans outil installé, la skill fonctionne
quand même (mode jugement LLM + citations), mais signale partout « non vérifié par outil ».
Chaque outil installé débloque la couverture déterministe d'un ou plusieurs rôles.

> **Hypothèse de travail** : tes projets sont en csproj « SDK-style » (balise
> `<TargetFrameworks>net48;net8.0-windows</TargetFrameworks>` ou équivalent). C'est le cas
> normal d'un multi-target 2024/2025/2026. Si un projet est en ancien format `.csproj`
> non-SDK, c'est signalé en fin de document.

---

## Légende

- 🔴 **ACTION MANUELLE** — toi seul peux la faire (téléchargement, installation système, décision).
- 🟡 **COMMANDE** — une ligne à lancer dans un terminal ; tu peux la lancer toi-même, ou laisser Claude Code la lancer.
- 🟢 **ÉDITION DE FICHIER** — un fichier de config à créer/modifier ; Claude Code peut le faire pour toi, je te donne le contenu exact pour contrôle.

---

## Pré-requis (à vérifier une seule fois)

### 🔴 ACTION MANUELLE 1 — Vérifier que le SDK .NET 8 est présent

Ouvre un terminal (PowerShell) et tape :

```
dotnet --list-sdks
```

Tu dois voir au moins une ligne commençant par `8.` (ex. `8.0.4xx`).
- Si oui → rien à faire, tu construis déjà du .NET 8, c'est attendu.
- Si non → télécharge et installe le **.NET 8 SDK** (pas seulement le Runtime) depuis
  https://dotnet.microsoft.com/download/dotnet/8.0 , puis relance la commande pour confirmer.

> Le SDK fournit gratuitement et sans installation supplémentaire : les **analyseurs Roslyn**,
> la commande **`dotnet list package --vulnerable`**, et **`dotnet test`**. Trois des quatre
> outils du socle sont donc déjà là dès que le SDK est présent.

---

## Socle Tier 1 — à installer AVANT le pilote (gratuit, natif, valeur maximale)

C'est le seul bloc que je te recommande de mettre en place avant la première exécution.
Il alimente directement les agents **Architecte**, **Mainteneur** et **Tests**.

### 🟢 ÉDITION 1 — Activer les analyseurs Roslyn pour toute la solution

Crée un fichier nommé **`Directory.Build.props`** à la **racine de la solution** (le dossier
qui contient le `.sln`). S'il existe déjà, fusionne ces balises dans le `<PropertyGroup>`.

```xml
<Project>
  <PropertyGroup>
    <!-- Active les analyseurs .NET (qualité + maintenabilité + sécurité de base) -->
    <EnableNETAnalyzers>true</EnableNETAnalyzers>
    <!-- Jeu de règles le plus récent disponible -->
    <AnalysisLevel>latest</AnalysisLevel>
    <!-- 'AllEnabledByDefault' = couverture maximale ; passe à 'Recommended' si trop bruyant -->
    <AnalysisMode>AllEnabledByDefault</AnalysisMode>
    <!-- Les analyseurs s'appliquent aussi à la target net48 (Revit 2024) -->
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
  </PropertyGroup>
</Project>
```

Effet : à chaque build, le compilateur émet des avertissements de qualité (complexité,
`IDisposable` non disposé, async mal géré, nommage, etc.) que l'agent lit comme des faits.
Placé en `Directory.Build.props`, c'est hérité automatiquement par **tous** les projets de la
solution, sur **toutes** les targets — pas de répétition par csproj.

### 🟢 ÉDITION 2 — Poser une cohérence de style mesurable (`.editorconfig`)

Crée un fichier **`.editorconfig`** à la racine de la solution. Version minimale qui donne du
signal à l'agent Mainteneur sans imposer un style rigide :

```ini
root = true

[*.cs]
# Conventions de base — l'agent Mainteneur s'appuie dessus pour juger la cohérence
indent_style = space
indent_size = 4
dotnet_sort_system_directives_first = true
csharp_prefer_braces = true:warning
dotnet_style_namespace_match_folder = true:suggestion
# Promeut quelques règles de qualité en avertissements visibles au build
dotnet_diagnostic.CA2007.severity = none   # ConfigureAwait : non pertinent en add-in WPF/Revit
dotnet_diagnostic.IDE0058.severity = suggestion
```

> Le `.editorconfig` est volontairement léger : son rôle ici n'est pas d'imposer TON style,
> mais de donner à l'agent une référence stable pour mesurer la **cohérence** du code.

### 🟡 COMMANDE 1 — Vérifier les dépendances vulnérables (déjà dans le SDK)

Aucune installation. Pour tester que ça répond, lance depuis le dossier de la solution :

```
dotnet list package --vulnerable --include-transitive
```

C'est l'outil de l'agent **Sécurité** pour les CVE NuGet. `--include-transitive` est important :
une faille arrive souvent par une dépendance indirecte, pas par ton csproj.

### 🟡 COMMANDE 2 — Ajouter la couverture de tests (Coverlet)

À lancer **dans le projet de tests** s'il existe (`cd` dans son dossier) :

```
dotnet add package coverlet.collector
```

Puis la couverture se collecte avec :

```
dotnet test --collect:"XPlat Code Coverage"
```

> ⚠️ Spécificité Revit importante : beaucoup de code d'add-in appelle l'API Revit, qui exige
> le **process Revit vivant** — donc non testable en `dotnet test` classique. Coverlet ne
> couvrira que ta **logique pure** (moteur de règles, parsing, modèles). C'est normal et
> voulu : l'agent Tests vise justement la **testabilité** (as-tu isolé la logique de l'API ?).
> Si le projet n'a **aucun** projet de tests, ce n'est pas un échec d'installation — c'est en
> soi un finding Tier 1 « absence de tests sur logique critique » que l'agent doit remonter.

---

## Tier 2 — à installer plus tard, quand tu actives la robustesse

### 🟢 ÉDITION 3 — Security Code Scan (analyse de sécurité approfondie)

Le nom du paquet n'est pas évident : le paquet maintenu est **`SecurityCodeScan.VS2019`**
(et non `SecurityCodeScan`, qui est l'ancienne version figée en 2021).

À ajouter **dans chaque csproj à auditer** (ou mieux, dans le `Directory.Build.props` pour
toute la solution) :

```xml
<ItemGroup>
  <PackageReference Include="SecurityCodeScan.VS2019" Version="5.6.7">
    <PrivateAssets>all</PrivateAssets>
    <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
  </PackageReference>
</ItemGroup>
```

> **Honnêteté sur la valeur réelle** : Security Code Scan est fortement orienté **web**
> (SQL injection, XSS, CSRF). Sur un add-in Revit desktop, l'essentiel de ses détections
> est hors sujet. Ce qui reste pertinent pour toi : **XXE** (injection d'entité externe XML —
> utile car tu parses du `.addin`, de l'IFC, du XML) et **path traversal** (lecture de
> fichiers non fiables). C'est pour ça qu'il est en Tier 2 et pas dans le socle : valeur
> réelle mais ciblée. Sa dernière mise à jour date de 2022 ; il reste le standard, mais ne
> compte pas dessus comme audit sécurité complet.

---

## Tier 3 — optionnel, seulement si la valeur le justifie sur tes gros projets

| Outil | Type | Quand l'envisager |
|---|---|---|
| **SonarLint** (extension VS/Rider, gratuit) | 🔴 installation IDE | Si tu veux du feedback qualité en continu pendant que tu codes, pas seulement en audit. |
| **SonarQube / SonarCloud** | service (gratuit pour open-source, payant sinon) | Si tu veux un tableau de bord historisé multi-projets. Lourd pour un dev solo. |
| **NDepend** | payant (licence) | Graphe de dépendances et métriques d'architecture poussées. Vraie valeur sur tes **gros** projets (l'add-in Revit), surdimensionné pour un utilitaire. |

Je ne recommande **aucun** de ces trois pour le pilote. À reconsidérer une fois le socle validé.

---

## Prompt Claude Cowork — installation automatique du socle Tier 1

Colle ce prompt dans Claude Cowork, **ouvert sur le dossier de ta solution**. Il fait tout ce
qui est automatisable (création des fichiers de config, ajout de Coverlet, commandes de
vérification) et s'arrête proprement sur ce qu'il ne peut pas faire lui-même.

> Il est volontairement limité au **socle Tier 1** (le set recommandé avant le pilote). Il
> n'installe **pas** Tier 2 (Security Code Scan) ni Tier 3 : on les ajoutera après validation,
> pour éviter le bruit de build au premier passage.

```
Tâche : préparer cette solution .NET desktop (add-in Revit multi-target) pour un audit qualité,
en installant uniquement le SOCLE TIER 1 d'outils déterministes. Travaille de façon idempotente :
si un fichier/réglage existe déjà, fusionne sans dupliquer. Ne touche à rien hors de la liste
ci-dessous. À la fin, donne-moi un compte rendu clair (ce qui a été fait, ce qui a été ignoré,
ce qui requiert une action de ma part).

PÉRIMÈTRE AUTORISÉ (et rien d'autre) :

1. VÉRIFICATION SDK (lecture seule)
   - Lance `dotnet --list-sdks`. S'il n'y a aucun SDK 8.x, NE TENTE PAS de l'installer :
     note-le comme action manuelle requise de ma part et continue le reste si possible.

2. ANALYSEURS ROSLYN — fichier `Directory.Build.props` à la racine de la solution (dossier du .sln)
   - S'il n'existe pas, crée-le. S'il existe, fusionne les propriétés ci-dessous dans un
     <PropertyGroup> sans écraser mes réglages existants :
       EnableNETAnalyzers=true
       AnalysisLevel=latest
       AnalysisMode=AllEnabledByDefault
       EnforceCodeStyleInBuild=true
   - Si une de ces propriétés est déjà définie à une autre valeur, NE l'écrase pas :
     signale le conflit dans le compte rendu et laisse ma valeur.

3. COHÉRENCE DE STYLE — fichier `.editorconfig` à la racine de la solution
   - S'il n'existe pas, crée-le avec une base légère : root=true, indent_style=space,
     indent_size=4, dotnet_sort_system_directives_first=true, csharp_prefer_braces=warning,
     dotnet_diagnostic.CA2007.severity=none.
   - S'il existe déjà, NE le réécris pas : signale qu'il est présent et laisse-le tel quel.

4. COUVERTURE DE TESTS — paquet Coverlet
   - Détecte s'il existe un projet de tests (csproj référençant xunit/nunit/mstest, ou nom en
     *.Tests). Si oui, ajoute le paquet `coverlet.collector` à CE projet via
     `dotnet add <projet-de-tests> package coverlet.collector`.
   - S'il n'existe AUCUN projet de tests, NE crée rien : note-le comme finding à part entière
     (« absence de projet de tests ») dans le compte rendu. Ce n'est pas une erreur d'install.

5. VÉRIFICATIONS (lecture seule, pour confirmer que les outils répondent)
   - `dotnet list package --vulnerable --include-transitive` à la racine.
   - `dotnet build` une fois, pour vérifier que l'ajout des analyseurs ne casse rien
     (des avertissements sont attendus et normaux — ne les corrige PAS, ne modifie aucun
     fichier source).

CONTRAINTES STRICTES :
- N'installe AUCUN logiciel système, runtime, SDK, ni extension d'IDE.
- N'installe PAS Security Code Scan ni aucun outil Tier 2/3.
- Ne modifie AUCUN fichier source .cs. Tu ne fais que de la config et des commandes de lecture.
- Ne fais aucun commit, aucun push.
- Montre-moi le diff de chaque fichier créé ou modifié.

COMPTE RENDU FINAL — liste en trois colonnes :
  [Fait] / [Ignoré car déjà présent ou non applicable] / [Action manuelle requise de ma part]
```

Deux remarques sur ce que Cowork fera :
- Le `dotnet build` va sortir beaucoup d'avertissements la première fois (c'est l'effet
  `AllEnabledByDefault`). C'est **voulu** — ces avertissements sont le carburant des agents.
  Le prompt interdit explicitement à Cowork de les « corriger », ce qui pollurait l'audit.
- Cowork modifie ta solution (deux fichiers de config + un paquet NuGet sur le projet de tests).
  C'est réversible. Relis le diff qu'il te montre avant de valider.

---

## Actions manuelles absolues — ce que Cowork ne PEUT PAS faire

Ce sont les seules choses qui dépendent **uniquement** de toi. Tout le reste est dans le prompt
ci-dessus.

1. 🔴 **Installer le SDK .NET 8 s'il manque.** Une installation système avec élévation de droits
   sort du périmètre de Cowork. Vu que tu construis déjà du multi-target .NET 8, il est
   quasi certainement déjà là — la vérification du prompt le confirmera. **S'il manque
   réellement** : dans ton environnement géré (UPGREAT / Empirum), une installation de SDK
   passe probablement par le portail logiciel managé plutôt que par un téléchargement direct ;
   c'est une demande à faire de ton côté, pas une action Cowork.

2. 🔴 **Décider d'installer (ou non) les outils Tier 2 / Tier 3.** Security Code Scan, SonarLint,
   NDepend ne sont volontairement PAS dans le périmètre automatique. Tier 2 s'ajoute quand tu
   actives la robustesse ; NDepend implique une **licence payante** (décision + achat = toi).
   Les extensions d'IDE (SonarLint) s'installent depuis l'interface de Visual Studio / Rider,
   action manuelle par nature.

3. 🔴 **Créer un projet de tests s'il n'en existe pas.** Si Cowork signale « aucun projet de
   tests », en créer un est une décision d'architecture (quel framework, quel périmètre) qui
   t'appartient — ce n'est pas une étape d'installation. L'agent Tests le remontera de toute
   façon comme finding Tier 1.

4. 🔴 **Relire et valider les diffs** que Cowork te présente avant de les garder. Trois fichiers
   au plus (`Directory.Build.props`, `.editorconfig`, le csproj de tests).

**Le socle Tier 1 suffit pour lancer le pilote.** Tier 2 et 3 viennent après validation.

---

## Cas particulier — projet en ancien format csproj (non-SDK)

Si `dotnet --list-sdks` fonctionne mais qu'un projet refuse `EnableNETAnalyzers` (typiquement
un vieux csproj avec `<Project ToolsVersion=...>` et des `<Reference>` manuelles), alors :
- les analyseurs Roslyn doivent être ajoutés via le paquet NuGet
  `Microsoft.CodeAnalysis.NetAnalyzers` au lieu de la balise `EnableNETAnalyzers` ;
- `dotnet list package --vulnerable` peut ne pas fonctionner (réservé aux projets PackageReference).

Si tu rencontres ce cas sur le pilote, signale-le moi : c'est en soi un finding architectural
(migration vers SDK-style recommandée) que l'agent Architecte remontera de toute façon.
