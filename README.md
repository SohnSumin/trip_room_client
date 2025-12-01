############################################################
Project: TripRoom - AI 기반 협업 여행 플래너
############################################################

## 프로젝트 소개

TripRoom은 친구, 가족, 동료와 함께 여행을 계획할 수 있는 크로스플랫폼 협업 여행 플래닝 애플리케이션입니다.
Google의 Gemini AI를 활용하여 여행 일정을 분석하고 최적의 동선과 계획을 추천하는 지능형 피드백 기능을 제공합니다.
사용자는 복잡한 고민 없이 효율적이고 즐거운 여행을 설계할 수 있습니다.

## 주요 기능

- 여행방 관리, 실시간 협업
- 스마트 장소 검색, 타임라인 기반 일정 관리
- AI 자동 일정 피드백 (백그라운드 비동기 처리)
- 여행 준비물 체크리스트
- Android, iOS, Web 크로스플랫폼 지원

## 기술 스택

- Client: Flutter (Dart)
- Server: Python Flask
- 데이터베이스: MongoDB
- AI: Google Gemini API, Google MAPs API
- 상태 관리: StatefulWidget, setState

## 프로젝트 구조

trip_room/
├─ client/ # Flutter 앱
│ └─ README.md # Client 실행 및 배포 안내
├─ server/ # Flask 서버
│ └─ README.md # Server 실행, API, 환경 변수 안내

############################################################
TripRoom Client
############################################################

## 사전 준비

- Flutter SDK 설치
- Android Studio / VS Code 등 개발 환경 설정

## 실행 방법

# 프로젝트 클론

- git clone [your-repository-url]

# 프로젝트 디렉터리 이동

- cd trip_room_client

# 패키지 설치

- flutter pub get

# 에뮬레이터 또는 기기에서 실행

- flutter run

## 배포 환경 (Vercel)

- 배포 주소: https://triproomclient.vercel.app
- Preview URL: \*-sohnsumins-projects.vercel.app
- CORS 설정: 정규 표현식 기반 와일드카드 패턴 적용
- API URL 연결: kIsWeb 시 https://triproomserver.up.railway.app 사용
