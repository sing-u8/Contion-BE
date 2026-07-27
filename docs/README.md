# 프로젝트 문서

이 디렉터리는 `Contion-Spring-BE`의 재구축 목적, 구현 정책 및 향후 의사결정 기록을 관리합니다.

제품 요구사항의 정본은 이 저장소가 아니라 원본 `worship-conti-maker-node-version` 저장소의 `docs/plan/`입니다. 이곳의 문서는 원본 요구사항을 대체하지 않고 Spring 재구현 방법과 판단 근거를 기록합니다.

## 문서 구조

| 경로 | 역할 |
| --- | --- |
| [`reimplementation-charter.md`](reimplementation-charter.md) | 프로젝트 목적, 범위, SSoT, 호환성 및 검증 원칙 |
| [`backlog.md`](backlog.md) | **열린 결정과 미배선 항목.** "다음에 무엇을 해야 하나"의 단일 목록 |
| [`design/`](design/) | Spring 고유 전술 결정. 특히 [`spring-translation-map.md`](design/spring-translation-map.md) — 원본을 재서술하지 않고 **차이만** 적는다 |
| [`upstream/`](upstream/) | 원본 기획 SSoT 핀의 근거·현재 SHA·이동 절차. `UPSTREAM.lock`은 기계 생성 |
| [`methodology/`](methodology/) | 스펙 게이트 개발 방법론 원문(Tier 0 헌법 + 가이드 + 템플릿) |
| [`rules/`](rules/) | 반복 적용되는 구현 및 코드 리뷰 규칙 |
| [`adr/`](adr/) | 선택지와 트레이드오프가 있는 단일 기술 결정의 기록 |
| `migration/` | 단계별 재구축 범위와 계약 동등성 결과를 기록할 예정인 디렉터리 |

## 문서 분류 원칙

- 프로젝트가 왜 존재하고 무엇을 보존하는가: `reimplementation-charter.md`
- 아직 결정하지 않았거나 배선하지 않은 것: `backlog.md`
- 원본 대비 무엇을 보존하고 무엇을 번역하는가: `design/spring-translation-map.md`
- 구현할 때 항상 지켜야 하는 규칙: `rules/`
- 선택지와 트레이드오프가 있는 단일 결정: `adr/`
- 특정 단계의 이관 범위와 검증 결과: `migration/`
- 제품 요구사항과 비즈니스 규칙: **핀된** `upstream/docs/plan/` (읽기 전용)

## 세션을 시작할 때

행동 규칙의 정본은 저장소 루트의 [`../CLAUDE.md`](../CLAUDE.md)이고, 그 최상위 기준은
[`methodology/CONSTITUTION.md`](methodology/CONSTITUTION.md)입니다. 새 클론이라면
`./scripts/setup-dev.sh`를 한 번 실행해 훅과 서브모듈을 배선합니다.

같은 제품 요구사항을 두 저장소에서 중복 편집하지 않습니다. Spring 구현 과정에서 요구사항 문제가 발견되면 원본 저장소의 기획 정합 작업으로 해결하고, 이 저장소에는 그 결정에 대한 링크나 적용 결과만 남깁니다.
