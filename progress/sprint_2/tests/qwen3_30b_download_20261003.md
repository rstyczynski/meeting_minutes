# Qwen3-30B-A3B local model download — 2026-10-03

This is download and integrity evidence, not a minutes-quality or runtime
validation. The source is the public [MLX 4-bit model
repository](https://huggingface.co/mlx-community/Qwen3-30B-A3B-Instruct-2507-4bit)
at pinned revision `e9675aa3ca5f900ccef55267914466d55ab325fa`. Its model
card identifies the underlying Qwen3-30B-A3B-Instruct-2507 weights. The
files were saved locally under the Git-ignored
`.models/qwen3-30b-a3b-instruct-2507-4bit/` directory. The previous
temporary-directory partial transfer was gone on 2026-10-03, so this was
a fresh download. The Hub client stalled before writing weight data;
direct `curl` transfers completed all four shards. Each direct transfer
used `--continue-at -` and bounded retries, allowing recovery from a
connection reset without discarding its partial file.

The pinned repository's [file
listing](https://huggingface.co/mlx-community/Qwen3-30B-A3B-Instruct-2507-4bit/tree/e9675aa3ca5f900ccef55267914466d55ab325fa)
contains 16 files, all present in the local model directory. The four
weight files total 17,181,071,994 bytes. The local `config.json` parses as
`model_type: qwen3_moe` with 4-bit quantization, and
`model.safetensors.index.json` names exactly these four shards. `stat` and
`shasum -a 256` matched the repository metadata for each file:

`model-00001-of-00004.safetensors` is 5,321,473,414 bytes, SHA-256
`70919a0f0b7d86c3100e30dfc2c72eb29909b841f9414b9c5ae3e8673ec9ff8c`.
`model-00002-of-00004.safetensors` is 5,366,644,780 bytes, SHA-256
`1a0387973b19b0bac1201358d1f56989deaf595da34f307ec29777fa6f8469b8`.
`model-00003-of-00004.safetensors` is 5,276,887,419 bytes, SHA-256
`d1a627729b2791dba7db5cda5dd0d24ea4c44c5131981c258598d5d0c80e0df3`.
`model-00004-of-00004.safetensors` is 1,216,066,381 bytes, SHA-256
`b02f0e9f626bd2f5bb41e057216c9d6f594ddeac91cc3f2161cc935d050a12c6`.

No MLX model load or minutes inference has run with these weights yet.
The 4B product default and the previous 4B/7B benchmark outcomes are
unchanged. A same-input AMI and Sejm run with the approved response gate
is needed before claiming that this larger model improves the product.
