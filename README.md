# Château de poche — app iPhone

Ce dépôt transforme le jeu web en vraie application iPhone. GitHub la compile sur un Mac dans le cloud et fournit un fichier `.ipa`, que tu installes avec **Sideloadly** depuis Windows. Tu n'as pas besoin de Mac.

## Contenu

| Élément | Rôle |
|---|---|
| `www/index.html` | Le jeu complet |
| `Sources/` | La petite app iOS qui affiche le jeu en plein écran et garde la sauvegarde |
| `Resources/Assets.xcassets` | L'icône de l'app |
| `project.yml` | La description du projet Xcode, générée automatiquement par XcodeGen |
| `.github/workflows/build-ios.yml` | La compilation automatique qui produit l'`.ipa` |

## 1. Mettre le projet sur GitHub

1. Crée un nouveau dépôt sur github.com, par exemple `chateau-de-poche`.
   - Si tu veux qu'il soit privé, ça fonctionne aussi, dans la limite des minutes gratuites de compilation.
2. Clique sur **Add file → Upload files**.
3. Glisse **tout le contenu** de ce dossier, y compris le dossier `.github`.
4. Clique sur **Commit changes**, en restant sur la branche `main`.

## 2. Récupérer l'IPA

1. Ouvre l'onglet **Actions**.
2. La compilation « Construire l'IPA iOS » démarre toute seule (environ 3 à 6 minutes).
   - Tu peux aussi la relancer avec **Run workflow**.
3. Quand elle est verte ✅, récupère l'IPA de l'une de ces deux façons :
   - l'onglet **Releases** du dépôt, puis `ChateauDePoche.ipa` ;
   - la compilation dans Actions, puis **Artifacts** et `ChateauDePoche-ipa` (c'est un zip qui contient l'`.ipa`).

## 3. Installer sur l'iPhone avec Sideloadly

1. Branche l'iPhone au PC et ouvre Sideloadly.
2. Glisse `ChateauDePoche.ipa` dans Sideloadly, entre ton identifiant Apple, puis clique sur **Start**.
3. Sur l'iPhone, va dans **Réglages → Général → VPN et gestion de l'appareil**, puis fais confiance à ton identifiant.
4. Sur iOS 16 ou plus récent, active aussi **Réglages → Confidentialité et sécurité → Mode développeur**. L'iPhone redémarre.

Avec un identifiant Apple gratuit, l'app doit être réinstallée tous les **7 jours** avec Sideloadly. La sauvegarde du jeu est conservée si tu réinstalles par-dessus sans supprimer l'app.

## Mettre le jeu à jour

1. Remplace `www/index.html` par la nouvelle version du jeu.
2. Fais un **Commit** : une nouvelle IPA est compilée automatiquement.
3. Installe-la avec Sideloadly, par-dessus l'ancienne.

Pour changer la version affichée, modifie `MARKETING_VERSION` dans `project.yml`.

## Bon à savoir

- **Son** : il suit le bouton silencieux de l'iPhone. Si tu n'entends rien, vérifie ce bouton.
- **Sauvegarde** : elle est stockée dans l'app et doublée dans les réglages de l'app, pour ne pas la perdre si iOS vide le cache.
- **Polices** : elles sont intégrées à l'app pendant la compilation, pour que le jeu soit joli même hors connexion.
- **Identifiant de l'app** : il vaut `com.elliot.chateaudepoche`. Sideloadly peut le modifier automatiquement si besoin.
