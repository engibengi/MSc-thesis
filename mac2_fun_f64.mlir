module {
  func.func @mac(%A: tensor<8x256xf64>,
                 %B: tensor<32x256xf64>,
                 %C: tensor<8x32xf64>) -> tensor<8x32xf64> {
    %Cres = linalg.generic {
        indexing_maps = [
            affine_map<(d0, d1, d2) -> (d0, d2)>,
            affine_map<(d0, d1, d2) -> (d1, d2)>,
            affine_map<(d0, d1, d2) -> (d0, d1)>
        ], iterator_types = ["parallel", "parallel", "reduction"]
    }
    ins(%A, %B:  tensor<8x256xf64>, tensor<32x256xf64>)
    outs(%C: tensor<8x32xf64>) {
        ^bb0(%a: f64, %b: f64, %c: f64):
            %prod = arith.mulf %a, %b: f64
            %sum = arith.addf %prod, %c : f64
            linalg.yield %sum: f64
    } -> tensor<8x32xf64>
    func.return %Cres : tensor<8x32xf64>
  }
}

