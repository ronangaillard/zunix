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

Tout fichier `.c` ajouté dans ce dossier est compilé et lié. Pas de bibliothèque C (`--nostdlib`).
