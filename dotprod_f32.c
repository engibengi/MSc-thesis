#define EL 4096

#define C_A  1
#define C_C  0
#define C_D  8

#include <snrt.h>
#include <math.h>
// Has matrices activations, weights, bias, and outputs
#include "dotprod_f32.h"

extern "C" float* dotprod(float *A, float *B, float *C);


void print(int core, char* mess) {
  printf("CORE::%02d::", core);
  for(int i=0; mess[i] != 0; ++i)
    printf("%c", mess[i]);
  printf("\n");
}

int main() {
  int this_core = snrt_cluster_core_idx();

  float *local_A = (float *)snrt_l1_next();
  float *local_B = local_A + EL;
  float *local_C = local_B + EL;
  float *local_D = local_C + 1;   

  if(this_core != C_D)
  {
    goto hb1;
  }

  // copy data in shared local memory
  if (snrt_is_dm_core()) {
    snrt_dma_start_1d(local_A, (volatile void *)A, EL * sizeof(float));
    snrt_dma_start_1d(local_B, (volatile void *)B, EL * sizeof(float));
    snrt_dma_start_1d(local_C, (volatile void *)C,  1 * sizeof(float));
    snrt_dma_start_1d(local_D, (volatile void *)D,  1 * sizeof(float));
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
    dotprod(local_A, local_B, local_C);
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
      local_D[0] += local_A[a] * local_B[a];
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
  else {
    print(this_core, "Correctness check");
    // Correctness check
    float d = fabs(local_C[0] - local_D[0]);
    if (d > 1E-2)  // Make sure to take into account NaNs (e.g.: happy path)
    {
      print(this_core, "BAD CODE EXIT!");
      printf("I = %d\n", 0);
      printf("d::%f\nl_C[i]::%f\nl_D[i]::%f\n", d, local_C[0], local_D[0]);
      snrt_cluster_hw_barrier();
      return 1;
    }
  }
hb3:
  print(this_core, "Good code exit");
  snrt_cluster_hw_barrier();
  return 0;
}
