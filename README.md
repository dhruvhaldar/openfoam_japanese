# OpenFOAM Japanese path smoke test

This repository provides a small Docker image that verifies whether an OpenFOAM
runtime can execute a known tutorial case from Unicode/Japanese directory paths.
It is intended as a black-box compatibility check for products that call
OpenFOAM on behalf of Japanese customers.

The image runs OpenFOAM with a UTF-8 locale and tests paths such as:

- `/tmp/openfoam-japanese-paths/日本語/case01`
- `/tmp/openfoam-japanese-paths/foam/ケース001`
- `/tmp/openfoam-japanese-paths/顧客A/解析/case01`
- `/tmp/openfoam-japanese-paths/顧客A/解析 ケース01`

The final case intentionally includes whitespace. Treat that as a stricter test
than Japanese characters alone, because shell quoting and some OpenFOAM path
handling can fail independently of Unicode support.

## Build

```bash
docker build -t openfoam-japanese-path-test .
```

By default, the Dockerfile uses `microfluidica/openfoam:13`, a community
multi-architecture OpenFOAM image. To test another supported image or version:

```bash
docker build \
  --build-arg OPENFOAM_IMAGE=microfluidica/openfoam:12 \
  -t openfoam-japanese-path-test:of12 \
  .
```

## Run

```bash
docker run --rm openfoam-japanese-path-test
```

A successful run prints `All Japanese/Unicode path smoke tests passed`.

To retain the generated cases and logs on the host:

```bash
mkdir -p ./test-output
docker run --rm \
  -e OPENFOAM_JAPANESE_TEST_ROOT=/work/output \
  -v "$PWD/test-output:/work/output" \
  openfoam-japanese-path-test
```

## What the test does

The container entrypoint script:

1. Forces `LANG=C.UTF-8` and `LC_ALL=C.UTF-8`.
2. Sources the OpenFOAM environment if needed.
3. Locates the `cavity` tutorial case.
4. Copies it into several ASCII and Japanese/Unicode paths.
5. Runs `blockMesh`, `foamDictionary`, and the solver configured in
   `system/controlDict` for each copied case.

If your product calls additional OpenFOAM utilities, extend
`scripts/test-japanese-paths.sh` with those exact commands so the image matches
your production workflow.
