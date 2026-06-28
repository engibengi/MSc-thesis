#define EL 16

#define C_A  1
#define C_C  0
#define C_D  8

#include <snrt.h>
#include <math.h>
// Has matrices activations, weights, bias, and outputs
#include "data_f64.h"

extern "C" double* kernelprod(double *A, double *B, double *C);


void print(int core, char* mess) {
  printf("CORE::%02d::", core);
  for(int i=0; mess[i] != 0; ++i)
    printf("%c", mess[i]);
  printf("\n");
}

int main() {
  int this_core = snrt_cluster_core_idx();
  double dk = 0.32;

  double *local_A = (double *)snrt_l1_next();
  double *local_B = local_A + EL * EL;
  double *local_C = local_B + EL * EL;
  double *local_D = local_C + EL * EL;   

  if(this_core != C_D)
  {
    goto hb1;
  }

  // copy data in shared local memory
  if (snrt_is_dm_core()) {
    snrt_dma_start_1d(local_A, (volatile void *)A, EL * EL * sizeof(double));
    snrt_dma_start_1d(local_B, (volatile void *)B, EL * EL * sizeof(double));
    snrt_dma_start_1d(local_C, (volatile void *)C, EL * EL * sizeof(double));
    snrt_dma_start_1d(local_D, (volatile void *)D, EL * EL * sizeof(double));
    snrt_dma_wait_all();
  }

hb1:
  snrt_cluster_hw_barrier();
  if(this_core != C_A && this_core != C_C)
  {
    goto hb2;
  }

  if(this_core == C_A)
  {
    snrt_fpu_fence();
    uint32_t start_cycle_acc = snrt_mcycle();
    kernelprod(local_A, local_B, local_C);
    snrt_fpu_fence();
    uint32_t cycles_duration = snrt_mcycle() - start_cycle_acc;
    print(this_core, "Accelerated kernel computed");
    printf("Accelerated kernel computation cycles: %u\n", cycles_duration); 
  }


  if(this_core == C_C)
  {
    snrt_fpu_fence();
    uint32_t start_cycle_std = snrt_mcycle();
    for(int a = 0; a < EL; ++a) { 
      for (int oc = 0; oc < EL; ++oc) {
        for (int ic = 0; ic < EL; ++ic) {
	  local_D[ a * EL + oc] += local_A[a * EL + ic] * local_B[oc * EL + ic];
	}
      }
    }
    snrt_fpu_fence();
    uint32_t cycles_duration = snrt_mcycle() - start_cycle_std;
    print(this_core, "Standard kernel computed");
    printf("Standard kernel computation cycles: %u\n", cycles_duration);
    goto hb2;
  }

hb2:
  snrt_cluster_hw_barrier();
  if(this_core != C_C) goto hb3;
  print(this_core, "Correctness check");
  // Correctness check
  for (int i = 0; i < EL * EL; i++) {
    double d = fabs(local_C[i] - local_D[i]);
    if (d > 1E-2)  // Make sure to take into account NaNs (e.g.: happy path)
    {
      print(this_core, "BAD CODE EXIT!");
      printf("I = %d\n", i);
      printf("d::%f\nl_C[i]::%f\nl_D[i]::%f\n", d, local_C[i], local_D[i]);
      snrt_cluster_hw_barrier();
      return 1+i;
    }
  }
hb3:
  print(this_core, "Good code exit");
  snrt_cluster_hw_barrier();
  return 0;
}
