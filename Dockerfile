# syntax=docker/dockerfile:1

# OpenFOAM Japanese/Unicode path smoke-test image.
# Uses the community multi-arch OpenFOAM images so this can run on amd64 and arm64.
# Override at build time if you need another distribution/version, e.g.:
#   docker build --build-arg OPENFOAM_IMAGE=microfluidica/openfoam:12 -t openfoam-japanese-path-test .
ARG OPENFOAM_IMAGE=microfluidica/openfoam:2506
FROM ${OPENFOAM_IMAGE}

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    OPENFOAM_JAPANESE_TEST_ROOT=/tmp/openfoam-japanese-paths

COPY scripts/test-japanese-paths.sh /usr/local/bin/test-japanese-paths
RUN chmod +x /usr/local/bin/test-japanese-paths

CMD ["/usr/local/bin/test-japanese-paths"]
