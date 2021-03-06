!*************************************************
! Laplace OpenACC Fortran Version
!
!*************************************************
program serial
      implicit none

      !Size of plate
      integer, parameter             :: columns=1000
      integer, parameter             :: rows=1000
      double precision, parameter    :: max_temp_error=0.01

      integer                        :: i, j, max_iterations, iteration=1
      double precision               :: dt=100.0
      real                           :: start_time, stop_time

      double precision, dimension(0:rows+1,0:columns+1) :: A_new, A

      print*, 'Maximum iterations [100-4000]?'
      read*,   max_iterations

      call cpu_time(start_time)      !Fortran timer

      call initialize(A)

      !do until error is minimal or until maximum steps
      !$acc data copy(A), create(A_new)
      do while ( dt > max_temp_error .and. iteration <= max_iterations)

         !$acc parallel loop
         do j=1,columns
            do i=1,rows
               A_new(i,j)=0.25*(A(i+1,j)+A(i-1,j)+ &
                                      A(i,j+1)+A(i,j-1) )
            enddo
         enddo
         !$acc end parallel loop

         dt=0.0

         !copy grid to old grid for next iteration and find max change
         !$acc parallel loop reduction(max:dt)
         do j=1,columns
            do i=1,rows
               dt = max( abs(A_new(i,j) - A(i,j)), dt )
               A(i,j) = A_new(i,j)
            enddo
         enddo
         !$acc end parallel loop

         !periodically print test values
         if( mod(iteration,100).eq.0 ) then
            !$acc update host(A_new)
            call track_progress(A_new, iteration)
         endif

         iteration = iteration+1

      enddo
      !$acc end data

      call cpu_time(stop_time)

      print*, 'Max error at iteration ', iteration-1, ' was ',dt
      print*, 'Total time was ',stop_time-start_time, ' seconds.'

end program serial


! initialize plate and boundery conditions
! temp_last is used to to start first iteration
subroutine initialize( A )
      implicit none

      integer, parameter             :: columns=1000
      integer, parameter             :: rows=1000
      integer                        :: i,j

      double precision, dimension(0:rows+1,0:columns+1) :: A

      A = 0.0

      !these boundary conditions never change throughout run

      !set left side to 0 and right to linear increase
      do i=0,rows+1
         A(i,0) = 0.0
         A(i,columns+1) = (100.0/rows) * i
      enddo

      !set top to 0 and bottom to linear increase
      do j=0,columns+1
         A(0,j) = 0.0
         A(rows+1,j) = ((100.0)/columns) * j
      enddo

end subroutine initialize


!print diagonal in bottom corner where most action is
subroutine track_progress(A_new, iteration)
      implicit none

      integer, parameter             :: columns=1000
      integer, parameter             :: rows=1000
      integer                        :: i,iteration

      double precision, dimension(0:rows+1,0:columns+1) :: A_new

      print *, '---------- Iteration number: ', iteration, ' ---------------'
      do i=5,0,-1
         write (*,'("("i4,",",i4,"):",f6.2,"  ")',advance='no'), &
                   rows-i,columns-i,A_new(rows-i,columns-i)
      enddo
      print *
end subroutine track_progress
