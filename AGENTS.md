# AGENTS.md

이 저장소는 Worship Conti Maker의 기존 NestJS 백엔드를 Java 21과 Spring Boot 4.1로 재구축한다.

코드, 설계, 계획 또는 규칙을 변경하기 전에 다음 문서를 확인한다.

1. [`docs/reimplementation-charter.md`](docs/reimplementation-charter.md)
2. 작업과 관련된 [`docs/rules/`](docs/rules/)
3. 원본 `worship-conti-maker-node-version` 저장소의 관련 `docs/plan/` 요구사항과 설계 문서
4. 원본 `BR_confusion_catalog.md`의 관련 혼동 경계
5. 원본 `tools/openapi/openapi.json`의 API 계약

## Source of Truth

- 제품 요구사항의 SSoT는 원본 저장소의 `docs/plan/`이다.
- 이 저장소의 문서는 Spring 재구현 정책과 기술 결정을 기록하며 제품 요구사항을 대체하지 않는다.
- 코드와 원본 기획 문서가 충돌하면 원본 기획 문서가 우선한다.
- BR 번호, 이벤트 이름, 식별자 또는 영속성 규칙을 기억에 의존해 인용하지 않는다.
- 원본 저장소를 읽을 수 없다면 요구사항을 추측하지 않는다.

## Reimplementation Policy

- 외부 API 계약과 제품 행위는 보존한다.
- 내부 구현은 Spring과 JPA의 관용에 맞게 재설계할 수 있다.
- NestJS 코드는 참조 구현이지 파일 단위 번역 대상이 아니다.
- 기능은 요구사항 확인, 실패 테스트, 구현, 통합 검증 및 계약 비교가 포함된 작은 수직 슬라이스로 진행한다.
- Spring에만 해당하는 중요한 기술 결정은 ADR로 남긴다.
- 같은 이벤트를 커스텀 Outbox와 Spring Modulith가 동시에 처리하도록 구현하지 않는다.

원본 저장소의 기본 로컬 상대 경로는 `../worship-conti-maker-node-version`이다.
