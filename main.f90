! ============================================================
! main.f90
! Programme principal — Solveur de chaleur 1D transitoire
!
! Équation : ρ·cp·∂T/∂t = k·∂²T/∂x² + q(x)
!   • Source gaussienne      q(x) = q0·exp(-½·((x-x0)/σ)²)
!   • CL de Robin aux deux extrémités
!   • Condition initiale uniforme T_init
!   • Schéma de Crank-Nicolson (ordre 2 en temps et espace)
!   • Résolution du système tridiagonal par l'algorithme de Thomas
!
! Utilisation :
!   ./solveur_chaleur [fichier_namelist]
!   (défaut : params.nml)
! ============================================================
program main
  use mod_precision
  use mod_params
  use mod_grille
  use mod_solver
  use mod_io
  implicit none

  ! Ligne de commande
  character(len=256) :: nml_file
  integer :: nargs

  ! Boucle temporelle
  integer  :: step, nout
  real(dp) :: time
  real(dp) :: T_min_glob, T_max_glob, T_min_loc, T_max_loc
  real(dp) :: alpha, dt_max_expl
  real(dp) :: T_mean

  ! ---------------------------------------------------------
  ! 1. Lecture du fichier namelist
  ! ---------------------------------------------------------
  nargs = command_argument_count()
  if (nargs >= 1) then
    call get_command_argument(1, nml_file)
  else
    nml_file = 'params.nml'
  end if

  call read_params(trim(nml_file))
  call print_params()

  ! Information sur la stabilité (pour référence explicite)
  alpha    = k_cond / (rho * cp)
  dt_max_expl = (Lx / real(Nx-1, dp))**2 / (2.0_dp * alpha)
  write(*, '(A,ES12.4,A)') '  [info] dt_max explicite = ', dt_max_expl, ' s'
  write(*, '(A,ES12.4,A)') '  [info] dt CN            = ', dt, ' s'
  if (dt > dt_max_expl) then
    write(*, '(A)') '  [info] dt > dt_max_expl : CN reste stable (schéma implicite).'
  end if

  ! ---------------------------------------------------------
  ! 2. Initialisation grille, solveur, E/S
  ! ---------------------------------------------------------
  call init_grille()
  call init_solver()
  call init_io()

  ! ---------------------------------------------------------
  ! 3. Écriture de l'état initial (step = 0)
  ! ---------------------------------------------------------
  time         = 0.0_dp
  nout         = 0
  T_min_glob   = minval(T)
  T_max_glob   = maxval(T)

  call write_step(0, time)
  nout = 1

  write(*, '(A)') ''
  write(*, '(A6, A14, A14, A14, A14)') &
    'Step', 'Temps [s]', 'T_min [K]', 'T_max [K]', 'T_moy [K]'
  write(*, '(A)') repeat('-', 60)

  T_mean = sum(T) / real(Nx, dp)
  write(*, '(I6, 4ES14.5)') 0, time, minval(T), maxval(T), T_mean

  ! ---------------------------------------------------------
  ! 4. Boucle temporelle
  ! ---------------------------------------------------------
  do step = 1, Nsteps

    call step_cn()
    time = real(step, dp) * dt

    ! Mise à jour des extrema globaux
    T_min_loc = minval(T)
    T_max_loc = maxval(T)
    if (T_min_loc < T_min_glob) T_min_glob = T_min_loc
    if (T_max_loc > T_max_glob) T_max_glob = T_max_loc

    ! Sortie périodique
    if (mod(step, output_freq) == 0) then
      call write_step(step, time)
      nout = nout + 1
      T_mean = sum(T) / real(Nx, dp)
      write(*, '(I6, 4ES14.5)') step, time, T_min_loc, T_max_loc, T_mean
    end if

  end do

  write(*, '(A)') repeat('-', 60)
  write(*, '(A,I6,A)') '  Simulation terminée. ', nout, ' fichiers écrits.'

  ! ---------------------------------------------------------
  ! 5. Script Gnuplot et animation
  ! ---------------------------------------------------------
  call write_gnuplot_script(nout, T_min_glob, T_max_glob)
  call run_gnuplot()

  ! ---------------------------------------------------------
  ! 6. Libération mémoire
  ! ---------------------------------------------------------
  call free_solver()
  call free_grille()

end program main
