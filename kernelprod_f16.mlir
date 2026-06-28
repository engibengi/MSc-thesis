module {
  func.func @kernelprod(%A: tensor<16x16xf16>,
                        %B: tensor<16x16xf16>,
                        %C: tensor<16x16xf16>) -> tensor<16x16xf16> {
    %Cres = linalg.generic {
        indexing_maps = [
            affine_map<(d0, d1, d2) -> (d0, d2)>,
            affine_map<(d0, d1, d2) -> (d1, d2)>,
            affine_map<(d0, d1, d2) -> (d0, d1)>
        ], iterator_types = ["parallel", "parallel", "reduction"]
    }
    ins(%A, %B:  tensor<16x16xf16>, tensor<16x16xf16>)
    outs(%C: tensor<16x16xf16>) {
        ^bb0(%a: f16, %b: f16, %c: f16):
            %prod = arith.mulf %a, %b: f16
            %sum = arith.addf %prod, %c : f16
            linalg.yield %sum: f16
    } -> tensor<16x16xf16>
    func.return %Cres : tensor<16x16xf16>
  }
}

