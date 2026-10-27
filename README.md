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
| `monitor.s` | moniteur en ROM, étape 0 : fait clignoter D8 (≈ 1 Hz), sans RAM ni port série |

Tout fichier `.c` ajouté dans ce dossier est compilé et lié. Pas de bibliothèque C (`--nostdlib`).

## Moniteur en ROM

```bash
make monitor          # build/monitor.rom (image complète de la flash)
make flash-monitor    # construit puis grave avec le TL866 (minipro)
make send-monitor     # sans graver : l'envoie à MONZ80 v2, qui le charge en 0x0000 et l'exécute
```

`monitor.s` est assemblé seul (sans C, sans crt0) à l'adresse 0x0000. `send-monitor` envoie le même fichier
(`build/monitor.ihx`) à MONZ80 v2, qui masque la ROM et le charge en RAM en 0x0000 : il tourne comme s'il avait
été gravé. `monitor.s` détecte s'il est en ROM ou en RAM et garde le bit ROM_DIS du latch en conséquence.

Par défaut, l'image vise la
SST39SF040 de la carte rev A : 128 Ko répétés 4 fois, car ses broches A17/A18 ne sont pas reliées. Pour une
SST39SF010 : `make flash-monitor ROM_CHIP=SST39SF010A ROM_COPIES=1`.
