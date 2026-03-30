! ============================================================
! mod_io.f90
! Module d'entrées/sorties :
!   • Création du répertoire de sortie
!   • Écriture du profil T(x) à chaque pas de sortie
!   • Génération du script Gnuplot pour l'animation GIF
! ============================================================
module mod_io
  use mod_precision
  use mod_params
  use mod_grille
  implicit none

contains

  ! ----------------------------------------------------------
  ! Crée le répertoire de sortie (ne fait rien si existant).
  ! ----------------------------------------------------------
  subroutine init_io()
    integer :: ios, cmdstat
    character(len=512) :: cmd

    cmd = 'mkdir -p ' // trim(output_dir)
    call execute_command_line(trim(cmd), wait=.true., exitstat=ios, cmdstat=cmdstat)
    if (cmdstat /= 0 .or. ios /= 0) then
      write(*, '(A,A)') '[io] Attention : impossible de créer ', trim(output_dir)
    else
      write(*, '(A,A)') '[io] Répertoire de sortie : ', trim(output_dir)
    end if
  end subroutine init_io

  ! ----------------------------------------------------------
  ! Écrit le profil T(x) courant dans un fichier ASCII.
  ! Nom : <output_dir>/T_NNNN.dat   (NNNN = numéro de pas)
  ! Format : deux colonnes  x [m]  T [K]
  ! La première ligne est un commentaire avec l'instant t.
  ! ----------------------------------------------------------
  subroutine write_step(step, time)
    integer,  intent(in) :: step
    real(dp), intent(in) :: time
    character(len=512) :: fname
    integer :: i

    write(fname, '(2A,I4.4,A)') trim(output_dir), '/T_', step, '.dat'

    open(unit=20, file=trim(fname), status='replace', action='write')
    write(20, '(A,ES14.6,A)') '# t = ', time, ' s'
    do i = 1, Nx
      write(20, '(2ES20.10)') x(i), T(i)
    end do
    close(20)
  end subroutine write_step

  ! ----------------------------------------------------------
  ! Génère le script Gnuplot pour l'animation GIF.
  ! Paramètres supplémentaires :
  !   nout    : nombre total de fichiers écrits (indices 0..nout-1)
  !   T_lo    : température minimale globale  [K]
  !   T_hi    : température maximale globale  [K]
  ! ----------------------------------------------------------
  subroutine write_gnuplot_script(nout, T_lo, T_hi)
    integer,  intent(in) :: nout
    real(dp), intent(in) :: T_lo, T_hi

    real(dp) :: ymin, ymax
    real(dp) :: margin

    margin = max(0.5_dp, 0.02_dp * (T_hi - T_lo))
    ymin   = T_lo - margin
    ymax   = T_hi + margin

    open(unit=30, file='plot_animation.gp', status='replace', action='write')

    write(30, '(A)') '# Script Gnuplot — Animation chaleur 1D'
    write(30, '(A)') '# Généré automatiquement par le solveur Fortran'
    write(30, '(A)') '#'
    write(30, '(A)') '# Utilisation :'
    write(30, '(A)') '#   gnuplot plot_animation.gp'
    write(30, '(A)') '# Produit : chaleur_1d.gif'
    write(30, '(A)') ''
    write(30, '(A)') 'set terminal gif animate delay 8 loop 0 size 900,600'
    write(30, '(A)') 'set output "chaleur_1d.gif"'
    write(30, '(A)') ''
    write(30, '(A)') 'set encoding utf8'
    write(30, '(A)') 'set xlabel "Position x  [m]"'
    write(30, '(A)') 'set ylabel "Temperature T  [K]"'
    write(30, '(A)') 'set grid'
    write(30, '(A)') 'set key top right'
    write(30, '(A)') 'set style line 1 lw 2 lc rgb "#CC0000"'
    write(30, '(A)') 'set style line 2 lw 1 lc rgb "#0055AA" dt 2'
    write(30, '(A)') ''
    write(30, '(A,ES14.6,A,ES14.6)')  'Lx   = ', Lx,   ''
    write(30, '(A,ES14.6)')  'ymin = ', ymin
    write(30, '(A,ES14.6)')  'ymax = ', ymax
    write(30, '(A,ES14.6)')  'dt_out = ', dt * real(output_freq, dp)
    write(30, '(A,I6)')      'nout   = ', nout
    write(30, '(A,I6)')      'freq   = ', output_freq
    write(30, '(A)') ''
    write(30, '(A)') 'set xrange [0 : Lx]'
    write(30, '(A)') 'set yrange [ymin : ymax]'
    write(30, '(A)') ''
    write(30, '(A)') 'do for [i=0:nout-1] {'
    write(30, '(A)') '  n    = i * freq'
    write(30, '(A)') '  t    = n * dt_out / freq'
    write(30, '(A,A,A)') '  fname = sprintf("', trim(output_dir), '/T_%04d.dat", n)'
    write(30, '(A)') '  set title sprintf("Chaleur 1D — Crank-Nicolson   t = %.1f s", t)'
    write(30, '(A)') '  plot fname using 1:2 with lines ls 1 title "T(x,t)"'
    write(30, '(A)') '}'

    close(30)
    write(*, '(A)') '[io] Script Gnuplot écrit : plot_animation.gp'
  end subroutine write_gnuplot_script

  ! ----------------------------------------------------------
  ! Lance Gnuplot pour produire l'animation.
  ! Si Gnuplot n'est pas disponible, un message est affiché.
  ! ----------------------------------------------------------
  subroutine run_gnuplot()
    integer :: ios, cmdstat
    call execute_command_line('gnuplot plot_animation.gp', wait=.true., &
                              exitstat=ios, cmdstat=cmdstat)
    if (cmdstat /= 0 .or. ios /= 0) then
      write(*, '(A)') '[io] Gnuplot non disponible ou erreur.'
      write(*, '(A)') '     Exécutez manuellement : gnuplot plot_animation.gp'
    else
      write(*, '(A)') '[io] Animation générée : chaleur_1d.gif'
    end if
  end subroutine run_gnuplot

end module mod_io
