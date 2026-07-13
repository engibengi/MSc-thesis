module {
  func.func @mac(%A: tensor<32x64xf16>,
                 %B: tensor<64x64xf16>,
                 %C: tensor<32x64xf16>) -> tensor<32x64xf16> {
    %Cres = linalg.generic {
        indexing_maps = [
            affine_map<(d0, d1, d2) -> (d0, d2)>,
            affine_map<(d0, d1, d2) -> (d1, d2)>,
            affine_map<(d0, d1, d2) -> (d0, d1)>
        ], iterator_types = ["parallel", "parallel", "reduction"]
    }
    ins(%A, %B:  tensor<32x64xf16>, tensor<64x64xf16>)
    outs(%C: tensor<32x64xf16>) {
        ^bb0(%a: f16, %b: f16, %c: f16):
            %prod = arith.mulf %a, %b: f16
            %sum = arith.addf %prod, %c : f16
            linalg.yield %sum: f16
    } -> tensor<32x64xf16>
    func.return %Cres : tensor<32x64xf16>
  }
}

