# Noyau Unix pour Z80

Noyau Unix pour un système Z80

```bash
make
```

## Fichiers

| Fichier | Rôle |
|---|---|
| `crt0.s` | entrée en 0x0000 (assembleur SDCC) |
| `main.c` | `main()` |
| `mon/` | moniteur en assembleur |

Tout fichier `.c` ajouté dans ce dossier est compilé et lié. Pas de bibliothèque C (`--nostdlib`).

## Moniteur en ROM

```bash
make monitor          # mon/build/monitor.rom (image complète de la flash)
make flash-monitor    # construit puis grave avec le TL866 (minipro)
make send-monitor     # envoie la rom au moniteur, qui le charge en 0x0000 et l'exécute,
                      # puis reste en console série (Ctrl-] pour quitter)
make serial           # console série seule (réinitialise la carte)
```

Ces cibles appellent `mon/Makefile` (`make -C mon`, cibles `all`, `flash`, `send`, `serial`).

Par défaut, l'image vise la
SST39SF040 de la carte rev A : 128 Ko répétés 4 fois, car ses broches A17/A18 ne sont pas reliées. Pour une
SST39SF010 : `make flash-monitor ROM_CHIP=SST39SF010A ROM_COPIES=1`.
