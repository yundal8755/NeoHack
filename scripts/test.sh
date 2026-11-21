#!/usr/bin/env bash
# 테스트 실행 스크립트
#
#   scripts/test.sh            # = core: 패키지 로직 테스트 (swift test, 시뮬레이터 없음, 수 초)
#   scripts/test.sh app        # 스냅샷 + UI 테스트 (xcodebuild, 시뮬레이터)
#   scripts/test.sh app -only-testing:RoufSnapshotTests
#   scripts/test.sh all        # core + app
#
# 시뮬레이터는 TEST_DESTINATION으로 바꿀 수 있다. 스냅샷 기준 이미지는 iPhone 17 / iOS 26.2에서 기록했다.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESTINATION="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.2}"

run_core() {
    (cd "$ROOT/Packages/RoufCore" && swift test "$@")
}

run_app() {
    local command=(xcodebuild test
        -project "$ROOT/Rouf.xcodeproj"
        -scheme Rouf
        -destination "$DESTINATION"
        "$@")

    if command -v xcbeautify >/dev/null 2>&1; then
        "${command[@]}" | xcbeautify
    else
        # xcbeautify가 없으면 빌드 오류, 실패한 테스트와 이유, 최종 결과만 남긴다.
        echo "💡 xcbeautify를 설치하면 빌드·테스트 로그를 더 보기 좋게 볼 수 있어요 (선택): brew install xcbeautify" >&2
        "${command[@]}" 2>&1 | grep -E --line-buffered \
            '(error:|^✘|^ +(open|Re-run|↳)|^✔ Test run|Test Case .*(passed|failed)|XCTAssert|\*\* .* \*\*)'
    fi
}

mode="${1:-core}"
[[ $# -gt 0 ]] && shift

case "$mode" in
    core) run_core "$@" ;;
    app) run_app "$@" ;;
    all) run_core && run_app "$@" ;;
    *)
        echo "사용법: $0 [core|app|all] [추가 인자...]" >&2
        exit 2
        ;;
esac
