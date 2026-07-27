/**
 * Notification BC — <b>Projection</b>이며 Aggregate 가 아니다.
 *
 * <p>원본 전략설계 v1.1.1이 구현 대조 결과 {@code Notification}·{@code PushSubscription}을
 * Aggregate Root → <b>Projection Root</b>로 재분류했다. 상태 전이가 "생성(멱등)"과
 * "readAt: null → 시각" 둘뿐이고, INV-NOTIF-01~06 중 트랜잭션 경계가 보호해야 할
 * 다중 필드 불변식이 없다(01=DB UNIQUE, 02=인가, 03=변경 경로 부재,
 * 04=스케줄러+ShedLock, 05=이벤트 핸들러, 06=트랜잭션 경계 밖 규칙).
 *
 * <p><b>따라서 이 BC 에는 {@code domain} 패키지를 두지 않는다.</b> 포트 · 어댑터 ·
 * 유스케이스로 구성한다. {@code ArchitectureRulesTest} 가 이를 강제한다.
 *
 * <p>Aggregate 승격 재검토 트리거 3종은
 * {@code docs/design/spring-translation-map.md} §6.4 참조.
 */
package org.worship.contionspringbe.notification;
