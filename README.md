주요 기능
1. 위치 기반 의료 기관 검색 : 사용자 주변의 병원 및 약국의 상세 정보(진료 시간, 진료 과목)를 실시간 조회
2. 실시간 응급 의료 정보 : 공공데이터 API를 연동하여 전국 응급실의 가용 병상 현황 및 실시간 상태 제공
3. AI 의료 챗봇 : Gemini 모델을 탑재하여 증상에 따른 가이드 및 의료 정보 상담 가능
4. 보안 인증 시스템 : JWT을 적용한 회원 관리 및 예약 시스템
5. 거리 계산 알고리즘 : 사용자 좌표 기반의 가장 가까운 시설 정렬

기술 스택
1. Framework : FastAPI
2. ORM : SQLALchemy
3. Validation : Pydantic
4. Database : PostgreSQL

AI & Data
1. LLM : Google Gemini 1.5 flash
2. 외부 API : 공공데이터포털(국립중앙의료원) 응급의료 및 병의원 API
3. Data Format : XML/JSON Parsing
