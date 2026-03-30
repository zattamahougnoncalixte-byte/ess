# Solveur de chaleur 1D — Crank-Nicolson (Fortran 90)

Solveur numérique complet pour l'équation de la chaleur 1D transitoire.

## Physique

```
ρ·cp·∂T/∂t = k·∂²T/∂x² + q(x)
```

| Élément | Description |
|---------|-------------|
| Source gaussienne | `q(x) = q0·exp(-½·((x−x0)/σ)²)` |
| CL gauche (Robin) | `k·dT/dx|₀ = h_L·(T(0) − T_inf_L)` |
| CL droite (Robin) | `-k·dT/dx|_L = h_R·(T(L) − T_inf_R)` |
| CI | `T(x,0) = T_init` (uniforme) |

## Méthode numérique

- **Crank-Nicolson** (ordre 2 en temps et en espace)
- **Algorithme de Thomas** (TDMA) pour le système tridiagonal
- Grille uniforme de `Nx` nœuds sur `[0, Lx]`

## Architecture modulaire

| Fichier | Contenu |
|---------|---------|
| `mod_precision.f90` | Type réel double précision (`dp`) |
| `mod_params.f90` | Paramètres physiques/numériques + lecture namelist |
| `mod_grille.f90` | Grille spatiale, tableaux `x`, `T`, `q` (allocatables) |
| `mod_solver.f90` | Schéma CN + algorithme de Thomas |
| `mod_io.f90` | Écriture des fichiers, génération du script Gnuplot |
| `main.f90` | Programme principal, boucle temporelle |
| `params.nml` | Fichier d'entrée (namelist) |
| `Makefile` | Compilation avec `gfortran` |

## Compilation et exécution

### Prérequis

- `gfortran` >= 6 (ou tout compilateur Fortran 2008)
- `gnuplot` >= 4.4 (pour l'animation GIF, optionnel)

### Compiler

```bash
make
```

### Lancer la simulation

```bash
./solveur_chaleur params.nml
```

ou simplement :

```bash
make run
```

### Générer l'animation (si Gnuplot installé)

L'animation est générée automatiquement en fin de simulation.
Pour la régénérer manuellement :

```bash
make anim
# ou
gnuplot plot_animation.gp
```

Cela produit le fichier **`chaleur_1d.gif`**.

## Configuration (`params.nml`)

```fortran
&physique
  rho       = 8000.0   ! masse volumique              [kg/m3]
  cp        =  500.0   ! capacité thermique            [J/(kg.K)]
  k_cond    =   50.0   ! conductivité thermique        [W/(m.K)]
  q0        = 1.0e6    ! amplitude source gaussienne   [W/m3]
  x0_src    =   0.5    ! centre de la gaussienne       [m]
  sigma_src =  0.05    ! écart-type gaussienne         [m]
  T_init    =  300.0   ! température initiale          [K]
  h_L       =  100.0   ! coeff convectif gauche        [W/(m2.K)]
  T_inf_L   =  300.0   ! température fluide gauche     [K]
  h_R       =  100.0   ! coeff convectif droit         [W/(m2.K)]
  T_inf_R   =  300.0   ! température fluide droit      [K]
/

&numerique
  Lx      = 1.0        ! longueur du domaine [m]
  Nx      = 101        ! nombre de nœuds
  dt      = 1.0        ! pas de temps        [s]
  Nsteps  = 300        ! nombre de pas
/

&sortie
  output_freq = 10     ! écriture tous les N pas
  output_dir  = 'output'
/
```

## Nettoyage

```bash
make clean
```

## Stabilité

Le schéma de Crank-Nicolson est **inconditionnellement stable** pour l'équation
de la chaleur avec conditions de Robin (h >= 0).
Le programme affiche le pas de temps maximal du schéma explicite à titre
indicatif (`dt_max_expl = dx^2 / (2*alpha)` avec `alpha = k/(rho*cp)`).
