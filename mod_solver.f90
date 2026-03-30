! ============================================================
! mod_solver.f90
! Module numérique : schéma de Crank-Nicolson + algorithme
! de Thomas pour le système tridiagonal.
!
! Équation discrétisée (nœuds intérieurs i = 2..Nx-1) :
!   -r·T_{i-1}^{n+1} + (1+2r)·T_i^{n+1} - r·T_{i+1}^{n+1}
!       = r·T_{i-1}^n + (1-2r)·T_i^n + r·T_{i+1}^n + f·q_i
!
! avec  r = k·Δt / (2·ρ·cp·Δx²)
!       f = Δt  / (ρ·cp)
!
! Nœud gauche (i=1) — Robin : k·dT/dx|₀ = h_L·(T₁ − T_inf_L)
!   (1+2r+2b_L)·T_1^{n+1} − 2r·T_2^{n+1}
!       = (1-2r-2b_L)·T_1^n + 2r·T_2^n + 4b_L·T_inf_L + f·q_1
!   avec  b_L = h_L·Δt / (2·ρ·cp·Δx)
!
! Nœud droit (i=Nx) — Robin : -k·dT/dx|_L = h_R·(T_N − T_inf_R)
!   -2r·T_{N-1}^{n+1} + (1+2r+2b_R)·T_N^{n+1}
!       = 2r·T_{N-1}^n + (1-2r-2b_R)·T_N^n + 4b_R·T_inf_R + f·q_N
!   avec  b_R = h_R·Δt / (2·ρ·cp·Δx)
! ============================================================
module mod_solver
  use mod_precision
  use mod_params
  use mod_grille
  implicit none

  ! Tableaux tridiagonaux (allocatables)
  real(dp), allocatable, private :: sub(:)   ! sous-diagonale  a(i), i=2..Nx
  real(dp), allocatable, private :: dia(:)   ! diagonale       b(i), i=1..Nx
  real(dp), allocatable, private :: sup(:)   ! sur-diagonale   c(i), i=1..Nx-1
  real(dp), allocatable, private :: rhs(:)   ! second membre   d(i)

contains

  ! ----------------------------------------------------------
  ! Allocation des tableaux internes du solveur.
  ! ----------------------------------------------------------
  subroutine init_solver()
    allocate(sub(Nx))
    allocate(dia(Nx))
    allocate(sup(Nx))
    allocate(rhs(Nx))
    sub = 0.0_dp
    dia = 0.0_dp
    sup = 0.0_dp
    rhs = 0.0_dp
    write(*, '(A)') '[solver] Solveur CN initialisé.'
  end subroutine init_solver

  ! ----------------------------------------------------------
  ! Libération.
  ! ----------------------------------------------------------
  subroutine free_solver()
    if (allocated(sub)) deallocate(sub)
    if (allocated(dia)) deallocate(dia)
    if (allocated(sup)) deallocate(sup)
    if (allocated(rhs)) deallocate(rhs)
  end subroutine free_solver

  ! ----------------------------------------------------------
  ! Algorithme de Thomas (TDMA) pour un système tridiagonal.
  !
  ! Résout  a_i·x_{i-1} + b_i·x_i + c_i·x_{i+1} = d_i
  !
  ! Entrée  : n, a(1:n), b(1:n), c(1:n), d(1:n)
  !           a(1) et c(n) non utilisés.
  ! Sortie  : solution dans le tableau sol(1:n)
  ! ----------------------------------------------------------
  subroutine thomas(n, a, b, c, d, sol)
    integer,  intent(in)    :: n
    real(dp), intent(in)    :: a(n), b(n), c(n), d(n)
    real(dp), intent(out)   :: sol(n)

    real(dp) :: b_tmp(n), d_tmp(n), w
    integer  :: i

    ! Copie locale (on ne modifie pas les tableaux appelants)
    b_tmp = b
    d_tmp = d

    ! Balayage avant
    do i = 2, n
      if (abs(b_tmp(i-1)) < tiny(1.0_dp)) then
        write(*, '(A,I6)') '[thomas] ERREUR : pivot nul à i=', i-1
        stop 2
      end if
      w = a(i) / b_tmp(i-1)
      b_tmp(i) = b_tmp(i) - w * c(i-1)
      d_tmp(i) = d_tmp(i) - w * d_tmp(i-1)
    end do

    ! Substitution arrière
    sol(n) = d_tmp(n) / b_tmp(n)
    do i = n-1, 1, -1
      sol(i) = (d_tmp(i) - c(i) * sol(i+1)) / b_tmp(i)
    end do
  end subroutine thomas

  ! ----------------------------------------------------------
  ! Un pas de Crank-Nicolson : T^n → T^{n+1}.
  ! Met à jour le tableau T du module mod_grille.
  ! ----------------------------------------------------------
  subroutine step_cn()
    integer  :: i
    real(dp) :: r, b_L, b_R, f
    real(dp) :: T_new(Nx)

    ! Paramètres adimensionnels CN
    r   = k_cond * dt / (2.0_dp * rho * cp * dx * dx)
    b_L = h_L    * dt / (2.0_dp * rho * cp * dx)
    b_R = h_R    * dt / (2.0_dp * rho * cp * dx)
    f   = dt / (rho * cp)

    ! --- Assemblage de la matrice tridiagonale ---

    ! Nœud gauche (i=1) — Robin gauche
    sub(1) =  0.0_dp
    dia(1) =  1.0_dp + 2.0_dp*r + 2.0_dp*b_L
    sup(1) = -2.0_dp * r
    rhs(1) = (1.0_dp - 2.0_dp*r - 2.0_dp*b_L)*T(1) &
             + 2.0_dp*r*T(2) &
             + 4.0_dp*b_L*T_inf_L &
             + f*q(1)

    ! Nœuds intérieurs (i=2..Nx-1)
    do i = 2, Nx-1
      sub(i) = -r
      dia(i) =  1.0_dp + 2.0_dp*r
      sup(i) = -r
      rhs(i) = r*T(i-1) + (1.0_dp - 2.0_dp*r)*T(i) + r*T(i+1) + f*q(i)
    end do

    ! Nœud droit (i=Nx) — Robin droit
    sub(Nx) = -2.0_dp * r
    dia(Nx) =  1.0_dp + 2.0_dp*r + 2.0_dp*b_R
    sup(Nx) =  0.0_dp
    rhs(Nx) = 2.0_dp*r*T(Nx-1) &
              + (1.0_dp - 2.0_dp*r - 2.0_dp*b_R)*T(Nx) &
              + 4.0_dp*b_R*T_inf_R &
              + f*q(Nx)

    ! --- Résolution par l'algorithme de Thomas ---
    call thomas(Nx, sub, dia, sup, rhs, T_new)

    ! --- Mise à jour du champ de température ---
    T = T_new

  end subroutine step_cn

end module mod_solver
