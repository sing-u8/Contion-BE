# Spec-Gated Development (스펙 게이트 개발)

> 진실(스펙)을 *머릿속이 아니라 문서*에 두고 → 단계를 넘어갈 때마다 그 문서를 *다시 읽고* → 에이전트가 한 번에 보는 정보는 *작게* 유지한다.

특정 스택·도메인·AI 도구에 묶이지 않은 **이식 가능한 AI 협업 개발 방법론**이다. 새 프로젝트에 이 `docs/methodology/` 폴더를 통째로 복사해서, 어떤 AI 에이전트(그리고 그 위에 얹는 어떤 스킬 팩)와 함께 쓰더라도 **기본 뼈대가 흔들리지 않게** 운영한다.

## 뼈대 한눈에 — SSoT 코어 + 3 루프

```
                ┌──────── SSoT 코어 ────────┐
                │ C1 진실의 외부화            │
                │ C2 전환 게이트              │
                │ C3 근거 기반 인용           │
                │ C4 작은 작업 컨텍스트        │
                └─────────────┬─────────────┘
          ┌───────────────────┼───────────────────┐
     [ 기획 루프 ]        [ 구현 루프 ]        [ 학습 루프 ]
   요구→전략→전술→데이터   게이트→스펙→계획      캡처→메모리/KB
   (단계마다 상위 재독)    →격리→red/green      →사례연구→플레이북
                         →리뷰→검증→통합        갱신→SSoT 피드백
          └───────────────────┴───────────────────┘
                    (같은 4불변식, 세 시간 규모)
```

세 루프는 **같은 4개 불변식(C1~C4)** 을 출시·증분·교훈 세 시간 규모로 반복하는 것이다. 뼈대의 정식 정의는 [CONSTITUTION.md](CONSTITUTION.md).

## 파일 지도

| 파일 | 무엇 | 언제 |
| --- | --- | --- |
| [CONSTITUTION.md](CONSTITUTION.md) | **단일 진실** — 뼈대 전부 + 우선순위·합성 조항 | 항상. 모든 규칙의 출처 |
| [00-one-pager.md](00-one-pager.md) | 북극성 1페이지 요약 | 처음 · 벽에 붙여두기 |
| [01-guide.md](01-guide.md) | 방법론 매뉴얼(원칙→3 루프→워크쓰루→점진 도입→에이전트 이식) | 배울 때 |
| [02-composition.md](02-composition.md) | 계층(Tier) 모델 · 스킬 팩 합성 · 새 팩 온보딩 | 팩을 얹을 때 |
| [entry-points/](entry-points/) | 툴별 얇은 포인터([AGENTS](entry-points/AGENTS.md)·[CLAUDE](entry-points/CLAUDE.md)·[GEMINI](entry-points/GEMINI.md)) → 헌법 | 설치 시 루트로 복사 |
| [skills/spec-gated-development/](skills/spec-gated-development/SKILL.md) | 게이트를 실제로 걷게 하는 운영 스킬 | (선택) 스킬 지원 도구에 |
| [hooks/](hooks/) | [pre-commit](hooks/pre-commit) · [CI 예시](hooks/ci-gate.example.yml) — 기계적 강제 | 불변식을 하드 강제할 때 |
| [templates/](templates/) | SSoT 골격 · 슬라이스 스펙/계획 · 리뷰 플레이북 · 사례 연구 | 새 프로젝트를 채울 때 |

## 설치 — 새 프로젝트에 이식

1. **번들 복사**: 이 `docs/methodology/` 폴더를 새 저장소로 복사한다.
2. **진입 포인터 배선**: `entry-points/`의 `CLAUDE.md`·`AGENTS.md`·`GEMINI.md`를 저장소 루트로 복사하고, 안의 `<repo>/docs/methodology/CONSTITUTION.md` 경로 placeholder를 실제 위치로 바꾼다. → 각 AI 도구가 자동 로드하는 진입 파일이 모두 헌법 하나를 가리키게 된다(대칭 포인터).
3. **기계적 훅 (권장)**: `hooks/pre-commit`을 훅 디렉터리로 복사 → `chmod +x` → `git config core.hooksPath <dir>`. 서버 쪽은 `hooks/ci-gate.example.yml` 참고. (설정·기본값은 각 파일 상단 주석 참조 — 기본은 보호브랜치 차단 ON, 마커 검사 warn.)
4. **운영 스킬 (선택)**: 스킬 개념이 있는 도구면 `skills/spec-gated-development/`를 그 도구의 스킬 위치(예: `.claude/skills/`)로 복사한다.
5. **SSoT 골격 채우기**: `templates/docs-skeleton/`을 프로젝트의 요구사항→전략→전술→데이터 문서로 채운다.

## 점진 도입 순서 — 한 번에 다 하지 말 것

가장 싸고 ROI 높은 것부터, 아플 때 강화한다 (YAGNI):

1. **day-1 최소**: 얇은 외부화 스펙(한 문단이라도) + 착수 게이트(재독) + 검증-전-완료.
2. **SSoT 코어**를 키운다: 계층 · 경계(혼동) 카탈로그 · 인용 규율.
3. **단계형 기획 루프**(요구→전략→전술→데이터)로 확장한다.
4. **학습 루프 인프라**(지속 메모리 · 아키텍처 KB · 사례 연구 · 플레이북 승격) + 훅을 warn→block으로 강화한다.

근거와 상세는 [01-guide.md](01-guide.md)의 「6. 점진 도입」.

## 다른 스킬 팩과 함께 쓰기

스킬 팩(예: superpowers · gstack)을 **얹어도 뼈대는 바뀌지 않는다** — 팩은 각 단계의 "어떻게"만 제공하고, 4개 비협상 항목(게이트 순서 · SSoT 우선 · 근거 인용 · 검증-전-완료)은 헌법이 소유한다. 팩은 예시일 뿐이며, 아직 없는 팩에도 같은 방식이 성립한다. 계층 모델 · 합성 매핑 · **새 팩 온보딩 레시피**는 [02-composition.md](02-composition.md).
