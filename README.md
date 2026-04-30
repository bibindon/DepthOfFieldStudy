# DepthOfFieldStudy

DirectX 9 で被写界深度を試すためのサンプルです。

## フォルダ構成

- `simple`
  - 元のサンプルです。
- `advance`
  - 発展版のサンプルです。
  - 画面中心付近にある近距離オブジェクトを検出したときだけ、被写界深度が徐々に有効になります。

## 動作確認

`advance\MultiPassRendering` を実行してください。

発展版では、カメラ手前のデモ用立方体が以下を繰り返します。

1. 画面右側で待機
2. 画面中央へ移動
3. 目の前で停止
4. 右側へ戻って停止

デモ用立方体が画面中心付近に入り、かつ `g_dofActivationDistance` より近いときに被写界深度が有効になります。切り替えは `g_dofBlend` によって徐々に行われます。

`1` キーを押すと、被写界深度の ON / OFF を切り替えられます。切り替え時も見た目は徐々に変化します。

画面左上には以下を表示します。

- `DOF`
  - 被写界深度の手動 ON / OFF 状態です。
- `Blend`
  - 被写界深度の適用率です。`0.00` で無効、`1.00` で最大です。
- `Center Object`
  - 近距離オブジェクトが画面中心判定に入っているかどうかです。
- `Distance`
  - 被写界深度判定に使われた近距離オブジェクトまでの距離です。

## パラメータ

### `advance\MultiPassRendering\main.cpp`

- `g_dofActivationDistance`
  - 被写界深度を有効化する距離しきい値です。
  - 単位はメートル扱いです。
- `g_dofCenterRadiusNdc`
  - 画面中心判定の広さです。
  - NDC 空間で使います。
- `g_dofBlendSpeed`
  - 被写界深度の ON / OFF が切り替わる速さです。
- `g_isDofEnabled`
  - 手動トグル用の状態です。

### `advance\MultiPassRendering\simple2.fx`

- `focalDistanceMeters`
  - ぼかさない中心距離です。
  - 単位はメートルです。
- `focusBandHalfWidthMeters`
  - ピントが合っているとみなす距離帯の半幅です。
  - 例えば `1.0` なら、焦点距離の前後 1m がピント内です。
- `blurRadiusPixels`
  - ぼかし半径です。
  - これは画面上のサンプル半径なので、単位はメートルではなくピクセルです。

## 実装メモ

- 1 パス目の [simple.fx](/C:/Users/bibindon/source/repos/DepthOfFieldStudy/advance/MultiPassRendering/simple.fx) では、MRT の `COLOR1` にカメラからの距離を格納しています。
- 深度テクスチャは [main.cpp](/C:/Users/bibindon/source/repos/DepthOfFieldStudy/advance/MultiPassRendering/main.cpp) で `D3DFMT_R32F` を使っています。
- 2 パス目の [simple2.fx](/C:/Users/bibindon/source/repos/DepthOfFieldStudy/advance/MultiPassRendering/simple2.fx) では、中心ピクセルの距離が `focalDistanceMeters ± focusBandHalfWidthMeters` に入っているときはそのピクセルをぼかしません。

## ビルド

Visual Studio 2026 の MSBuild は以下を使用できます。

`C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin`

ソリューション:

- `advance\MultiPassRendering.sln`
- `simple\MultiPassRendering.sln`
