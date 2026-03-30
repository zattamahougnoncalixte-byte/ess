! ============================================================
! mod_precision.f90
! Module de précision numérique
! Définit le type réel double précision utilisé partout.
! ============================================================
module mod_precision
  implicit none

  ! Précision double : 15 chiffres décimaux significatifs,
  ! exposant jusqu'à 307.
  integer, parameter :: dp = selected_real_kind(15, 307)

end module mod_precision
