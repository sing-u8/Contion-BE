# ADR — 아키텍처 결정 기록

**여기에 무엇이 들어가나**: 선택지와 트레이드오프가 있는 **Spring 고유 단일 결정**.

**여기에 들어가지 않는 것**:
- 제품 요구사항·BR — 원본 `upstream/docs/plan/`이 정본이다. 여기서 새로 만들지 않는다.
- 반복 적용되는 규칙 → [`../rules/`](../rules/)
- 원본 대비 번역·차이의 목록 → [`../design/spring-translation-map.md`](../design/spring-translation-map.md)
- 아직 결정하지 않은 것 → [`../backlog.md`](../backlog.md)

## 파일 이름

`NNNN-kebab-case-title.md` (예: `0001-jwt-filter-vs-oauth2-resource-server.md`)

## 최소 구조

```markdown
# ADR-NNNN: <결정 한 줄>

- 상태: Proposed | Accepted | Superseded by ADR-NNNN
- 일자: YYYY-MM-DD
- Upstream pin: <SHA>

## 맥락
무엇을 결정해야 했고, 어떤 제약이 있었나. 원본 계약상 보존해야 하는 것을 명시한다.

## 선택지
각 선택지와 그 대가. 채택하지 않은 것도 왜 아닌지 남긴다.

## 결정
무엇을 택했나.

## 근거
왜. 원본 문서를 인용할 때는 verbatim + 출처(문서·버전·섹션).

## 결과
무엇이 따라오는가. 강제 수단이 있으면 명시한다(테스트·가드·리뷰 체크리스트).

## 재검토 트리거
무엇이 바뀌면 이 결정을 다시 보는가.
```

## 대기 중인 ADR

[`../backlog.md`](../backlog.md) §1 참조. 현재 §1.1(인증 필터 방식)·§1.2(예외 클래스
이름)가 ADR 대상으로 표시돼 있다.
