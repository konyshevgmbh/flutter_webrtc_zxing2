# RTMPose ONNX Model

Place the RTMPose ONNX model file here as `rtmpose.onnx`.

## Recommended model

**RTMPose-s (COCO 17 keypoints, 256×192)**

Download from the MMPose model zoo:
https://github.com/open-mmlab/mmpose/tree/main/projects/rtmpose

Direct download (RTMPose-s body7):
```
https://download.openmmlab.com/mmpose/v1/projects/rtmposev1/onnx_sdk/rtmpose-s_simcc-body7_pt-body7_420e-256x192-acd4a1ef_20230504.zip
```

After downloading, extract and rename the `.onnx` file to `rtmpose.onnx` and place it in this directory.

## Input / Output spec

| | Value |
|---|---|
| Input shape | `[1, 3, 256, 192]` NCHW float32 |
| Mean | `[123.675, 116.28, 103.53]` |
| Std | `[58.395, 57.12, 57.375]` |
| Output 0 (simcc_x) | `[1, 17, 384]` |
| Output 1 (simcc_y) | `[1, 17, 512]` |
| Keypoints | 17 COCO body keypoints |


USE 
https://github.com/open-mmlab/mmpose/tree/main/projects/rtmpose

RTMPose-t*	256x192	65.9	91.44	63.18	3.34	0.36	3.20	1.06	9.02	pth
onnx