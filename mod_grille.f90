! ============================================================
! mod_grille.f90
! Module de gestion de la grille spatiale et des champs.
!
! Grille uniforme de Nx nœuds :
!   x(1) = 0,  x(i) = (i-1)*dx,  x(Nx) = Lx
!   dx = Lx / (Nx - 1)
!
! Tableaux allocatables :
!   x   — coordonnées spatiales [m]
!   T   — température courante  [K]
!   q   — terme source          [W/m³]
! ============================================================
module mod_grille
  use mod_precision
  use mod_params
  implicit none

  real(dp), allocatable :: x(:)   ! coordonnées des nœuds
  real(dp), allocatable :: T(:)   ! température courante
  real(dp), allocatable :: q(:)   ! terme source gaussien
  real(dp) :: dx                  ! pas spatial

contains

  ! ----------------------------------------------------------
  ! Allocation et initialisation de la grille.
  !   • x(i)  : nœuds uniformes de 0 à Lx
  !   • T(i)  : T_init partout
  !   • q(i)  : gaussienne centrée en x0_src
  ! ----------------------------------------------------------
  subroutine init_grille()
    integer :: i
    real(dp) :: arg

    if (Nx < 2) then
      write(*, '(A)') '[grille] ERREUR : Nx doit être >= 2.'
      stop 1
    end if

    ! Allocation
    allocate(x(Nx))
    allocate(T(Nx))
    allocate(q(Nx))

    ! Pas spatial
    dx = Lx / real(Nx - 1, dp)

    ! Coordonnées et initialisations
    do i = 1, Nx
      x(i) = real(i - 1, dp) * dx
      T(i) = T_init
      arg  = (x(i) - x0_src) / sigma_src
      q(i) = q0 * exp(-0.5_dp * arg * arg)
    end do

    write(*, '(A,I6,A,ES10.3,A)') &
      '[grille] Grille initialisée : Nx=', Nx, '  dx=', dx, ' m'
  end subroutine init_grille

  ! ----------------------------------------------------------
  ! Libération des tableaux.
  ! ----------------------------------------------------------
  subroutine free_grille()
    if (allocated(x)) deallocate(x)
    if (allocated(T)) deallocate(T)
    if (allocated(q)) deallocate(q)
  end subroutine free_grille

end module mod_grille
