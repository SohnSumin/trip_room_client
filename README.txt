############################################################

Project: TripRoom - AI 기반 협업 여행 플래너

############################################################

1. 프로젝트 소개 (Introduction)

TripRoom은 친구, 가족, 동료와 함께 여행을 계획할 수 있는 크로스플랫폼 협업 여행 플래닝 애플리케이션입니다.

단순한 일정 관리를 넘어, Google의 Gemini AI를 활용하여 생성된 여행 일정을 분석하고 최적의 동선과 계획을 추천해주는 지능형 피드백 기능을 제공하는 것이 핵심입니다. 사용자는 복잡한 고민 없이 효율적이고 즐거운 여행을 설계할 수 있습니다.

2. 주요 기능 (Features)

여행방 관리 (Trip Room Management)

  - 여행방 생성, 수정, 삭제 및 대표 이미지, 목적지, 여행 기간 설정
  - 방장(Owner) 권한을 통한 여행방 관리

실시간 협업 (Real-time Collaboration)

  - 사용자 ID 검색을 통한 여행 멤버 초대
  - 여행방에 참여한 멤버 목록 확인 및 관리 (방장 기능)
  - 모든 멤버가 함께 일정을 확인하고 계획에 참여

스마트 장소 검색 (Smart Place Search with Google Maps)

  - (핵심 기능) Google Places API를 연동하여 장소 검색 기능의 편의성을 극대화했습니다.
  - 사용자가 '도톤보리 이치란'과 같이 일부 키워드만 입력해도, '이치란 도톤보리점 별점'과 같은 정확한 공식 명칭과 주소를 찾아 자동으로 완성해줍니다.
  - 이를 통해 사용자는 부정확한 장소명으로 인한 혼동 없이 명확하게 일정을 등록할 수 있습니다.

타임라인 기반 일정 관리 (Timeline-based Scheduling)

  - 시간대별/날짜별 그리드 UI를 통해 직관적인 일정 추가 및 수정
  - 식사, 관광, 항공, 숙소 등 활동 유형에 따른 아이콘 자동 표시
  - 상세 시간(분 단위) 설정으로 유연한 계획 수립 가능

AI 자동 일정 피드백 (AI Schedule Feedback & Optimization)

  - (핵심 기능) 버튼 클릭 한 번으로 작성된 전체 여행 일정에 대한 AI 피드백을 요청합니다.
  - Gemini AI가 비효율적인 동선, 불가능한 계획, 빠진 항목 등을 분석하여 종합적인 피드백 메시지를 제공합니다.
  - AI가 자동으로 수정한 최적화된 일정 변경 내역을 사용자에게 제시하고 적용할 수 있습니다.

여행 준비물 체크리스트 (Checklist)

  - 여행방 멤버들과 공유하는 준비물 체크리스트 기능
  - 항목 추가, 삭제 및 완료 상태 체크 가능

크로스플랫폼 지원 (Cross-Platform)

  - Flutter 프레임워크를 사용하여 Android, iOS, Web에서 동일한 사용자 경험을 제공합니다.

3. 기술 스택 및 아키텍처 (Tech Stack & Architecture)

클라이언트 (Client): Flutter (Dart)

상태 관리 (State Management): StatefulWidget, setState

HTTP 통신 (HTTP Client): http package

AI: Google Gemini API 연동 (서버를 통해 호출)

백엔드 (Backend): Python Flask

데이터베이스 (Database): MongoDB

아키텍처 개선 시도 (Architecture Improvement Attempt)

  - 코드의 유지보수성 및 확장성을 높이기 위해 MVVM (Model-View-ViewModel) 아키텍처로의 리팩토링을 시도했습니다.
  - 이 과정은 refactor/mvvm 브랜치에 저장되어 있으며, 상태 관리 로직을 View에서 분리하려는 노력을 확인할 수 있습니다.

4. 실행 방법 (How to Run)

사전 준비

Flutter SDK 설치

Android Studio / VS Code 등 개발 환경 설정

백엔드 서버 실행 (로컬 환경: http://127.0.0.1:5000 또는 http://10.0.2.2:5000)

클라이언트 실행

프로젝트를 클론하거나 다운로드합니다.
       git clone [your-repository-url]    

프로젝트 디렉터리로 이동합니다.
       cd trip_room_client    

필요한 패키지를 설치합니다.
       flutter pub get    

에뮬레이터 또는 실제 기기를 연결하고 앱을 실행합니다.
       flutter run    

4.3. 배포 환경 실행 (Deployment Environment)

4.3.1. 백엔드 서버 (Railway)

백엔드 서버는 Railway에 배포되어 있습니다.

실행 명령어 (Procfile):
Railway 환경의 특성상, Gunicorn은 $PORT 환경 변수 값과 관계없이 내부적으로 8080 포트에 바인딩되어야 프록시로부터 트래픽을 정상적으로 수신합니다.

web: gunicorn --bind 0.0.0.0:8080 app:app


공개 엔드포인트:

[https://triproomserver.up.railway.app](https://triproomserver.up.railway.app)


환경 변수:
Railway 프로젝트 설정에 Maps_API_KEY와 GEMINI_API_KEY가 설정되어야 합니다.

4.3.2. 클라이언트 (Vercel)

클라이언트 애플리케이션은 Vercel에 웹 버전으로 배포되어 있습니다.

배포 주소:
https://triproomclient.vercel.app (프로덕션) 또는 Preview URL (*-sohnsumins-projects.vercel.app 패턴)

CORS 설정:
클라이언트의 다양한 Vercel Origin을 수용하기 위해, 백엔드 서버(app.py)의 flask-cors 설정에 정규 표현식 기반의 와일드카드 패턴이 적용되어 있습니다.

API URL 연결:
클라이언트 코드(config.dart 등)는 kIsWeb이 참일 경우, 배포된 서버 주소인 https://triproomserver.up.railway.app을 사용하도록 동적으로 설정되어 있습니다. 이 설정을 통해 로컬 개발 환경과 배포 환경이 분리되어 관리됩니다.