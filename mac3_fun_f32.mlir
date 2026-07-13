module {
  func.func @mac(%A: tensor<32x64xf32>,
                 %B: tensor<64x64xf32>,
                 %C: tensor<32x64xf32>) -> tensor<32x64xf32> {
    %Cres = linalg.generic {
        indexing_maps = [
            affine_map<(d0, d1, d2) -> (d0, d2)>,
            affine_map<(d0, d1, d2) -> (d1, d2)>,
            affine_map<(d0, d1, d2) -> (d0, d1)>
        ], iterator_types = ["parallel", "parallel", "reduction"]
    }
    ins(%A, %B:  tensor<32x64xf32>, tensor<64x64xf32>)
    outs(%C: tensor<32x64xf32>) {
        ^bb0(%a: f32, %b: f32, %c: f32):
            %prod = arith.mulf %a, %b: f32
            %sum = arith.addf %prod, %c : f32
            linalg.yield %sum: f32
    } -> tensor<32x64xf32>
    func.return %Cres : tensor<32x64xf32>
  }
}

