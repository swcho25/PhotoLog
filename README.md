## iOS 프로그래밍 기말 미니 프로젝트 - PhotoLog

<br>

![180](https://github.com/user-attachments/assets/42cb0392-5ba1-4547-b44f-ccc1b2a902f7)

<br>

## 프로젝트 개요

사진 한 장으로 간편하게 하루를 기록하는 사진 기반 감성 일기 어플

<br>

## 프로젝트 설명

바쁜 현대인들에게 매일 부지런하게 그 날 있었던 일을 일기로 기록하는 것은 쉽지 않은 일입니다.  
그래서 자신이 일기를 작성하고 싶은 날에 촬영한 사진 한 장만으로 간편하게 하루를 기록할 수 있는  
사진 기반 감성 일기 어플인 PhotoLog를 제작했습니다.  
사용자가 사진을 업로드하면 사진의 메타데이터(촬영 날짜, 촬영 장소)를 추출하고,  
그 정보를 바탕으로 일기를 자동 작성해줍니다.  
이 기능을 통해 사용자는 매일 부지런히 직접 일기를 작성할 필요 없이,  
시간이 지나서도 사진 한 장을 통해 그날을 간편하게 기록할 수 있게 될 것입니다.  

<br>

## 주요 기능
- Firebase Authentication을 통해 구글 로그인
- 일기 작성 시 사용자가 첨부한 사진의 메타데이터(촬영 날짜, 촬영 장소)를 자동으로 추출
- 사진의 메타데이터를 기반으로 OpenAI API를 통해 감성 일기 자동 작성
- 일기 저장 시 이미지 데이터는 Firebase Storage에 저장

<br>

## 주요 화면

<table>
  <tr>
    <td align="center" valign="top">
      <b>1. 로그인</b><br>
      ─────────────<br>
      <img src="https://github.com/user-attachments/assets/45f186b0-a00e-4950-a198-24fa708e2c83" width="200"/><br>
      ─────────────<br>
      구글 계정으로 로그인
    </td>
    <td align="center" valign="top">
      <b>2. 홈 화면</b><br>
      ─────────────<br>
      <img src="https://github.com/user-attachments/assets/918152b6-64ab-446d-accb-31d17b75d166" width="200"/><br>
      ─────────────<br>
      작성한 일기를 연도별/월별로 확인
    </td>
    <td align="center" valign="top">
      <b>3. 검색 화면</b><br>
      ─────────────<br>
      <img src="https://github.com/user-attachments/assets/4338c1f4-decf-44ad-885b-5cb2931be3ec" width="200"/><br>
      ─────────────<br>
      입력 키워드를 통해 일기 검색
    </td>
  </tr>
  <tr>
    <td align="center" valign="top">
      <b>4. 일기 생성 화면 </b><br>
      ─────────────<br>
      <img src="https://github.com/user-attachments/assets/cc05cfe7-2a2c-439b-bb04-a66e7e818a3f" width="200"/><br>
      ─────────────<br>
      사진을 첨부해 일기 생성 준비
    </td>
    <td align="center" valign="top">
      <b>5. 일기 생성 결과 화면</b><br>
      ─────────────<br>
      <img src="https://github.com/user-attachments/assets/7a7659cd-d5d6-465c-82a7-ffd89ac1c300" width="200"/><br>
      ─────────────<br>
      생성된 일기 확인 (수정 가능)
    </td>
    <td align="center" valign="top">
      <b>6. 내 사진 화면</b><br>
      ─────────────<br>
      <img src="https://github.com/user-attachments/assets/98a0e754-1de0-40a5-b582-d14e45908c94" width="200"/><br>
      ─────────────<br>
      작성한 일기의 이미지 한 번에 확인
    </td>
  </tr>
  <tr>
    <td align="center" valign="top">
      <b>7. 일기 상세 화면</b><br>
      ─────────────<br>
      <img src="https://github.com/user-attachments/assets/fbdbed89-34da-4b20-bf9c-10ae5072e8e8" width="200"/><br>
      ─────────────<br>
      작성한 일기의 내용 확인
    </td>
    <td align="center" valign="top">
      <b>8. 일기 수정 및 삭제</b><br>
      ─────────────<br>
      <img src="https://github.com/user-attachments/assets/cbe12a39-fa60-42e7-b03b-4a619e5c8f46" width="200"/><br>
      ─────────────<br>
      일기 상세 화면에서 수정 및 삭제 가능
    </td>
    <td align="center" valign="top">
      <b>9. 사용자 프로필 화면</b><br>
      ─────────────<br>
      <img src="https://github.com/user-attachments/assets/6870f606-20b0-4f15-b022-862aa1c5ed9e" width="200"/><br>
      ─────────────<br>
      사용자 정보 및 로그아웃
    </td>
  </tr>
</table>  

<br>

## 주요 적용 기술

| 분류           | 내용 |
|----------------|------|
| **개발 언어**   | <img src="https://img.shields.io/badge/Swift-FA7343?style=for-the-badge&logo=swift&logoColor=white"/> |
| **개발 도구**   | <img src="https://img.shields.io/badge/Xcode-147EFB?style=for-the-badge&logo=xcode&logoColor=white"/> <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/> <img src="https://img.shields.io/badge/OpenAI-412991?style=for-the-badge&logo=openai&logoColor=white"/> |
| **주요 패키지** | Firebase (11.14.0) / Google Sign-In (8.0.0) / SDWebImage (5.21.1)<br>DGCharts (5.1.0) / Promises (2.4.0) |


<br>

## 프로젝트 결과물

| 항목 | 링크 |
|------|------|
| 시연 영상 | https://youtube.com/shorts/QG0_LWdH0VI |
