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

発展版では、カメラの手前にあるデモ用オブジェクトが画面中心を左右に横切ります。
このオブジェクトが画面中心付近に入ると被写界深度が徐々に強くなり、中心から外れると徐々に弱くなります。

画面左上には以下を表示します。

- `DOF Blend`
  - 被写界深度の適用率です。`0.00` で無効、`1.00` で最大です。
- `Center Object`
  - 近距離オブジェクトが画面中心判定に入っているかどうかです。
- `Distance`
  - 被写界深度判定に使われた近距離オブジェクトまでの距離です。

## 調整項目

`advance\MultiPassRendering\main.cpp`

- `g_dofActivationDistance`
  - 被写界深度を有効化する距離しきい値です。
- `g_dofCenterRadiusNdc`
  - 画面中心判定の広さです。NDC 空間で使います。
- `g_dofBlendSpeed`
  - 被写界深度の ON/OFF が切り替わる速さです。

`advance\MultiPassRendering\simple2.fx`

- `focalDepth`
  - ぼかさない中心距離です。
- `inFocusBand`
  - ぼかさない距離の幅です。
- `blurStrength`
  - ぼかしの強さです。

## ビルド

Visual Studio 2026 の MSBuild は以下を使用できます。

`C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin`

ソリューション:

- `advance\MultiPassRendering.sln`
- `simple\MultiPassRendering.sln`
