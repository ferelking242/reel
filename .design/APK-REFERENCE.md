# Référence APK TikTok (analyse statique)

Source : `com.zhiliaoapp.musically` (APK universel, 483 Mo, SHA-256
`7321ae3537572004956e2308c7eb5b1d82e6eb536c2c2fac432f3d8a1801ff70`).
Outils : `apktool 2.11.1 d -s` + pont jadx de REA (`rea inspect-android-package`).
Aucune exécution de l'APK : analyse purement statique.

## Polices (`assets/font/`)

| Fichier | Licence | Utilisation |
|---|---|---|
| `TikTokSans-VF.otf` | SIL OFL 1.1 (© TikTok Inc.) | texte courant — **embarquée** |
| `TikTok-Display-{Regular,Medium,Bold}.otf` | propriétaire | titres marketing — non redistribuée |
| `TikTok-Text-{Regular,Medium,Bold}.otf` | propriétaire | ancienne famille texte — non redistribuée |

Axes de la variable font : `wght 300→900`, `opsz 12→36`, `wdth 75→150`,
`slnt -6→0`. Instances statiques utilisées dans `assets/fonts/` : 400/500/600/700,
`opsz=20`, `wdth=100`, `slnt=0`.

## Couleurs (`res/values/colors.xml`)

Valeurs les plus fréquentes :

```
#FE2C55  marque / like / live          23 occurrences
#161823  texte principal (thème clair) 20
#25F4EE  accent cyan                    3
#0BE09B  vert (statut live/réussi)      5
#FF3B5C  rouge secondaire               5
#FFFFFF / #E6FFFFFF / #BFFFFFFF / #80FFFFFF / #57FFFFFF / #33FFFFFF / #1EFFFFFF
#000000 / #99000000 / #66000000 / #4D000000
#161823 à 0F / 1E / 33 / 80 / BF / C0 / E6 (dégradés d'opacité)
```

Notre `AppTokens` utilise déjà ces valeurs ; l'échelle d'opacité (80/57/33/1E/0F)
sert aux séparateurs, textes secondaires et scrims.

## Typographie (`res/values/styles.xml`)

Tailles observées : `10, 11, 12, 13, 14, 15, 16, 17 sp` pour l'UI,
`24, 34, 48, 60, 96 sp` pour le display. Graisses dominantes : 400 / 500 / 600 / 700.

Notre échelle (`caption 10` → `display 28`) suit la même progression.

## Espacements (`res/values/dimens.xml`)

Grille de 4 dp : `2, 4, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48` (les plus utilisés :
8, 12, 16, 4, 24, 20). Gouttière horizontale 16 dp, avatar 48 dp, icône 24 dp.

## Icônes

- 4 641 drawables vectoriels + 1 801 WebP en `xxhdpi`.
- Convention : `viewportWidth/Height = 24`, `width/height = 24 dp`,
  `strokeWidth = 2.0` pour les traits principaux, `1.0` pour les filets,
  remplissages pleins avec `fillColor="@android:color/white"` teintés à l'exécution.
- `ReelGlyph` suit cette convention (grille 24, traits 1.6→2.2) sans copier les
  tracés d'origine : géométries redessinées à la main.
