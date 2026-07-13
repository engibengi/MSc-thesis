module {
  func.func @dotprod(%A: tensor<4096xf16>,
                     %B: tensor<4096xf16>,
                     %C: tensor<f16>) -> tensor<f16> {
    %Cres = linalg.generic {
        indexing_maps = [
            affine_map<(d0) -> (d0)>,
            affine_map<(d0) -> (d0)>,
            affine_map<(d0) -> ()>
        ], iterator_types = ["reduction"]
    }
    ins(%A, %B:  tensor<4096xf16>, tensor<4096xf16>)
    outs(%C: tensor<f16>) {
        ^bb0(%a: f16, %b: f16, %c: f16):
            %prod = arith.mulf %a, %b: f16
            %sum = arith.addf %prod, %c : f16
            linalg.yield %sum: f16
    } -> tensor<f16>
    func.return %Cres : tensor<f16>
  }
}

