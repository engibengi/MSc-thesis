module {
  func.func @dotprod(%A: tensor<4096xf64>,
                     %B: tensor<4096xf64>,
                     %C: tensor<f64>) -> tensor<f64> {
    %Cres = linalg.generic {
        indexing_maps = [
            affine_map<(d0) -> (d0)>,
            affine_map<(d0) -> (d0)>,
            affine_map<(d0) -> ()>
        ], iterator_types = ["reduction"]
    }
    ins(%A, %B:  tensor<4096xf64>, tensor<4096xf64>)
    outs(%C: tensor<f64>) {
        ^bb0(%a: f64, %b: f64, %c: f64):
            %prod = arith.mulf %a, %b: f64
            %sum = arith.addf %prod, %c : f64
            linalg.yield %sum: f64
    } -> tensor<f64>
    func.return %Cres : tensor<f64>
  }
}

