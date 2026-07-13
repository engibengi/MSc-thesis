module {
  func.func @mac(%A: tensor<8x256xf32>,
                 %B: tensor<32x256xf32>,
                 %C: tensor<8x32xf32>) -> tensor<8x32xf32> {
    %Cres = linalg.generic {
        indexing_maps = [
            affine_map<(d0, d1, d2) -> (d0, d2)>,
            affine_map<(d0, d1, d2) -> (d1, d2)>,
            affine_map<(d0, d1, d2) -> (d0, d1)>
        ], iterator_types = ["parallel", "parallel", "reduction"]
    }
    ins(%A, %B:  tensor<8x256xf32>, tensor<32x256xf32>)
    outs(%C: tensor<8x32xf32>) {
        ^bb0(%a: f32, %b: f32, %c: f32):
            %prod = arith.mulf %a, %b: f32
            %sum = arith.addf %prod, %c : f32
            linalg.yield %sum: f32
    } -> tensor<8x32xf32>
    func.return %Cres : tensor<8x32xf32>
  }
}

