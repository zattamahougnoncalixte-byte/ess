# ============================================================
# Makefile — Solveur de chaleur 1D (Crank-Nicolson)
# ============================================================

FC      = gfortran
FFLAGS  = -O2 -Wall -Wextra -std=f2008

PROG    = solveur_chaleur
SRCS    = mod_precision.f90 mod_params.f90 mod_grille.f90 \
          mod_solver.f90 mod_io.f90 main.f90
OBJS    = $(SRCS:.f90=.o)

# ---- Règle principale ----------------------------------------
all: $(PROG)

$(PROG): $(OBJS)
	$(FC) $(FFLAGS) -o $@ $^

# ---- Compilation dans l'ordre (dépendances de modules) -------
mod_precision.o: mod_precision.f90
	$(FC) $(FFLAGS) -c $<

mod_params.o: mod_params.f90 mod_precision.o
	$(FC) $(FFLAGS) -c $<

mod_grille.o: mod_grille.f90 mod_precision.o mod_params.o
	$(FC) $(FFLAGS) -c $<

mod_solver.o: mod_solver.f90 mod_precision.o mod_params.o mod_grille.o
	$(FC) $(FFLAGS) -c $<

mod_io.o: mod_io.f90 mod_precision.o mod_params.o mod_grille.o
	$(FC) $(FFLAGS) -c $<

main.o: main.f90 mod_precision.o mod_params.o mod_grille.o \
        mod_solver.o mod_io.o
	$(FC) $(FFLAGS) -c $<

# ---- Lancement avec le namelist par défaut -------------------
run: all
	./$(PROG) params.nml

# ---- Animation Gnuplot (si les données existent déjà) --------
anim:
	gnuplot plot_animation.gp

# ---- Nettoyage -----------------------------------------------
clean:
	rm -f *.o *.mod $(PROG) plot_animation.gp chaleur_1d.gif
	rm -rf output

.PHONY: all run anim clean
