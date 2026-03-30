! ============================================================
! mod_params.f90
! Module des paramètres physiques, numériques et de sortie.
! Les valeurs par défaut peuvent être écrasées par le fichier
! namelist (params.nml).
! ============================================================
module mod_params
  use mod_precision
  implicit none

  ! --- Paramètres physiques ---
  real(dp) :: rho       = 8000.0_dp   ! masse volumique            [kg/m³]
  real(dp) :: cp        =  500.0_dp   ! capacité thermique massique [J/(kg·K)]
  real(dp) :: k_cond    =   50.0_dp   ! conductivité thermique      [W/(m·K)]
  real(dp) :: q0        = 1.0e6_dp    ! amplitude de la source Q    [W/m³]
  real(dp) :: x0_src    =   0.5_dp    ! centre de la gaussienne     [m]
  real(dp) :: sigma_src =  0.05_dp    ! écart-type de la gaussienne [m]
  real(dp) :: T_init    =  300.0_dp   ! température initiale        [K]

  ! --- Conditions aux limites de Robin ---
  !  Gauche  (x=0) :  k·dT/dx|₀  =  h_L·(T(0) − T_inf_L)
  !  Droite  (x=L) : −k·dT/dx|_L = h_R·(T(L) − T_inf_R)
  real(dp) :: h_L     =  100.0_dp    ! coeff convectif gauche [W/(m²·K)]
  real(dp) :: T_inf_L =  300.0_dp    ! température fluide gauche [K]
  real(dp) :: h_R     =  100.0_dp    ! coeff convectif droit  [W/(m²·K)]
  real(dp) :: T_inf_R =  300.0_dp    ! température fluide droit  [K]

  ! --- Paramètres numériques ---
  real(dp) :: Lx      =   1.0_dp     ! longueur du domaine   [m]
  integer  :: Nx      =  101          ! nombre de nœuds
  real(dp) :: dt      =   1.0_dp     ! pas de temps          [s]
  integer  :: Nsteps  =  300          ! nombre de pas de temps

  ! --- Paramètres de sortie ---
  integer           :: output_freq = 10      ! écriture tous les N pas
  character(len=256) :: output_dir  = 'output'

contains

  ! ----------------------------------------------------------
  ! Lecture des paramètres depuis un fichier namelist.
  ! ----------------------------------------------------------
  subroutine read_params(filename)
    character(len=*), intent(in) :: filename
    integer :: uid, ios

    namelist /physique/  rho, cp, k_cond, q0, x0_src, sigma_src, T_init, &
                         h_L, T_inf_L, h_R, T_inf_R
    namelist /numerique/ Lx, Nx, dt, Nsteps
    namelist /sortie/    output_freq, output_dir

    open(unit=10, file=trim(filename), status='old', action='read', iostat=ios)
    if (ios /= 0) then
      write(*, '(A)') '[params] Attention : fichier namelist introuvable.' // &
                      ' Valeurs par défaut utilisées.'
      return
    end if
    uid = 10

    read(uid, nml=physique,  iostat=ios)
    if (ios /= 0) write(*, '(A)') '[params] Attention : erreur lecture &physique'
    rewind(uid)

    read(uid, nml=numerique, iostat=ios)
    if (ios /= 0) write(*, '(A)') '[params] Attention : erreur lecture &numerique'
    rewind(uid)

    read(uid, nml=sortie,    iostat=ios)
    if (ios /= 0) write(*, '(A)') '[params] Attention : erreur lecture &sortie'

    close(uid)
  end subroutine read_params

  ! ----------------------------------------------------------
  ! Affichage récapitulatif des paramètres.
  ! ----------------------------------------------------------
  subroutine print_params()
    write(*, '(A)') repeat('=', 52)
    write(*, '(A)') '     Solveur de chaleur 1D — Crank-Nicolson'
    write(*, '(A)') repeat('=', 52)
    write(*, '(A)') '  Physique :'
    write(*, '(A,ES12.4,A)') '    rho      = ', rho,       ' kg/m3'
    write(*, '(A,ES12.4,A)') '    cp       = ', cp,        ' J/(kg·K)'
    write(*, '(A,ES12.4,A)') '    k        = ', k_cond,    ' W/(m·K)'
    write(*, '(A,ES12.4,A)') '    q0       = ', q0,        ' W/m3'
    write(*, '(A,ES12.4,A)') '    x0_src   = ', x0_src,    ' m'
    write(*, '(A,ES12.4,A)') '    sigma    = ', sigma_src, ' m'
    write(*, '(A,ES12.4,A)') '    T_init   = ', T_init,    ' K'
    write(*, '(A)') '  Conditions Robin :'
    write(*, '(A,ES12.4,A)') '    h_L      = ', h_L,     ' W/(m2·K)'
    write(*, '(A,ES12.4,A)') '    T_inf_L  = ', T_inf_L, ' K'
    write(*, '(A,ES12.4,A)') '    h_R      = ', h_R,     ' W/(m2·K)'
    write(*, '(A,ES12.4,A)') '    T_inf_R  = ', T_inf_R, ' K'
    write(*, '(A)') '  Numérique :'
    write(*, '(A,ES12.4,A)') '    Lx       = ', Lx,   ' m'
    write(*, '(A,I6)')        '    Nx       = ', Nx
    write(*, '(A,ES12.4,A)') '    dt       = ', dt,   ' s'
    write(*, '(A,I6)')        '    Nsteps   = ', Nsteps
    write(*, '(A,ES12.4,A)') '    alpha    = ', k_cond/(rho*cp), ' m2/s'
    write(*, '(A)') '  Sortie :'
    write(*, '(A,I6)')        '    freq     = ', output_freq
    write(*, '(A,A)')         '    dossier  = ', trim(output_dir)
    write(*, '(A)') repeat('=', 52)
  end subroutine print_params

end module mod_params
