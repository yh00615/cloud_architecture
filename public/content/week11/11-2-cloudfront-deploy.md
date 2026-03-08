---
title: 'Amazon CloudFront 배포 구성'
week: 11
session: 2
awsServices:
  - Amazon CloudFront
learningObjectives:
  - Amazon CloudFront의 핵심 기능과 CDN으로서의 역할을 이해할 수 있습니다.
  - Amazon CloudFront의 동작 방식(엣지 로케이션, 캐시 동작)을 설명할 수 있습니다.
  - 오리진 액세스 제어(OAC)를 활용한 오리진 보호 정책을 구성할 수 있습니다.
---

> [!TIP]
> 이 실습에서는 **CloudFront CDN**을 구성하여 **S3 웹사이트**의 성능을 향상시킵니다. S3 버킷에 정적 웹사이트를 호스팅하고, **CloudFront 배포**를 생성하여 오리진으로 S3를 지정합니다. **OAI(Origin Access Identity)**를 설정하여 S3 버킷을 프라이빗으로 유지하면서 CloudFront만 접근할 수 있도록 합니다. CloudFront 도메인으로 접속하여 전 세계 **엣지 로케이션**에서 캐싱된 콘텐츠가 빠르게 전달되는 것을 확인합니다.

> [!DOWNLOAD]
> [week11-2-cloudfront-deploy.zip](/files/week11/week11-2-cloudfront-deploy.zip)
>
> - `setup-11-2.sh` - 사전 환경 구축 스크립트 (Amazon S3 버킷, 샘플 웹 파일 생성)
> - `cleanup-11-2.sh` - 리소스 정리 스크립트
> - 태스크 0: 사전 환경 구축 (setup-11-2.sh 실행)

> [!CONCEPT] Amazon CloudFront란?
>
> Amazon CloudFront는 전 세계 **엣지 로케이션**을 통해 콘텐츠를 빠르게 전송하는 CDN(Content Delivery Network) 서비스입니다.
>
> - **엣지 로케이션**: 전 세계 400개 이상의 거점에서 콘텐츠를 캐싱하여 사용자에게 가장 가까운 위치에서 응답합니다
> - **오리진(Origin)**: 원본 콘텐츠가 저장된 서버입니다 (S3 버킷, EC2, ALB 등)
> - **OAC(Origin Access Control)**: S3 버킷에 CloudFront를 통해서만 접근할 수 있도록 제한하는 보안 설정입니다
> - **캐시 무효화(Invalidation)**: 엣지 로케이션에 캐싱된 콘텐츠를 강제로 갱신합니다

## 태스크 0: 사전 환경 구축

> [!NOTE]
> 실습을 시작하기 전에 AWS 콘솔 우측 상단에서 현재 리전을 확인하세요. 올바른 리전에서 작업하고 있는지 반드시 확인해야 합니다.

1. 위 DOWNLOAD 섹션에서 `week11-2-cloudfront-deploy.zip` 파일을 다운로드합니다.

2. AWS Management Console에 로그인한 후 상단의 **CloudShell** 아이콘을 선택하여 CloudShell을 실행합니다.

3. CloudShell 상단의 **Actions** → **Upload file**을 선택하여 다운로드한 ZIP 파일을 업로드합니다.

4. 업로드가 완료되면 다음 명령어로 압축을 해제합니다:

```bash
unzip week11-2-cloudfront-deploy.zip
```

5. setup 스크립트에 실행 권한을 부여하고 실행합니다:

```bash
chmod +x setup-11-2.sh
./setup-11-2.sh
```

6. 스크립트 실행 중 생성 계획이 표시되면 `y`를 입력하여 진행합니다.

> [!NOTE]
> 사전 환경 구축에 약 1-2분이 소요됩니다. 스크립트가 완료될 때까지 기다립니다.

7. 스크립트가 완료되면 출력 메시지에서 다음 리소스가 생성되었는지 확인합니다:

| 리소스 | 이름 |
|--------|------|
| S3 버킷 | cloudarchitect-lab-s3website-[계정 ID] |
| 샘플 파일 | index.html, error.html |

✅ **태스크 완료**: 사전 환경 구축이 완료되었습니다.

> [!TIP]
> **CloudShell 파일 정리**: 실습이 완전히 종료된 후, 업로드한 ZIP 파일과 스크립트를 삭제하여 CloudShell 스토리지를 정리할 수 있습니다:
> ```bash
> rm -f week11-2-cloudfront-deploy.zip setup-11-2.sh cleanup-11-2.sh
> ```
> CloudShell 스토리지는 리전별로 1GB까지 무료 제공되며, 파일 정리는 선택사항입니다.


## 태스크 1: 사전 구축된 환경 확인

8. 상단 검색창에서 `S3`를 검색하고 **S3**를 선택합니다.

9. Amazon S3 콘솔의 버킷 목록에서 **cloudarchitect-lab-s3website-[계정 ID]** 형태의 버킷을 선택합니다.

10. **Objects** 탭에서 `index.html`과 `error.html` 파일이 업로드되어 있는지 확인합니다.

11. 상단 탭 중 **Properties** 탭을 선택하고 페이지 맨 아래의 **Static website hosting** 섹션을 확인합니다 (이 실습에서는 비활성화 상태).

12. 상단 탭 중 **Permissions** 탭을 선택하여 초기 퍼블릭 액세스 정책을 확인합니다.

> [!NOTE]
> 이 실습에서는 S3 정적 웹사이트 호스팅 대신 Amazon CloudFront OAC를 사용합니다. S3 정적 웹사이트 호스팅은 버킷을 퍼블릭으로 공개해야 하지만, OAC를 사용하면 S3 버킷을 퍼블릭으로 공개하지 않고도 CloudFront를 통해 콘텐츠를 제공할 수 있어 보안이 강화됩니다.

✅ **태스크 완료**: S3 버킷과 샘플 파일이 정상적으로 구축되어 있습니다.


## 태스크 2: Amazon CloudFront 배포 생성

> [!CONCEPT] OAC(Origin Access Control)
>
> OAC는 S3 버킷에 Amazon CloudFront 배포만 접근할 수 있도록 제한하는 보안 메커니즘입니다. OAC를 사용하면 S3 버킷을 퍼블릭으로 공개하지 않아도 CloudFront를 통해 콘텐츠를 안전하게 제공할 수 있습니다. 기존의 OAI(Origin Access Identity)보다 서명 방식이 개선되어 보안이 강화된 최신 방식입니다.

13. 상단 검색창에서 `CloudFront`를 검색하고 **CloudFront**를 선택합니다.

14. Amazon CloudFront 콘솔에서 [[Create distribution]] 버튼을 클릭합니다.

### 2.1 Step 1: Get started

15. **Distribution name**에 `CloudArchitect-Lab-Distribution`을 입력합니다.

16. **Description**은 비워둡니다 (선택 사항).

17. **Distribution type**에서 **Single website or app**을 선택합니다.

18. **Domain**은 비워둡니다 (선택 사항).

19. **Tags**는 비워둡니다 (선택 사항).

20. [[Next]] 버튼을 클릭합니다.

### 2.2 Step 2: Specify origin

21. **Origin type**에서 **Amazon S3**를 선택합니다.

22. **S3 origin**에서 [[Browse S3]] 버튼을 클릭합니다.

23. 버킷 목록에서 **cloudarchitect-lab-s3website-[계정ID]** 버킷을 선택하고 [[Choose]] 버튼을 클릭합니다.

24. **Allow private S3 bucket access to CloudFront - Recommended** 체크박스가 선택되어 있는지 확인합니다.

> [!NOTE]
> 이 옵션을 선택하면 CloudFront가 자동으로 OAC(Origin Access Control)를 생성하고 S3 버킷 정책을 업데이트할 수 있는 권한을 요청합니다.

25. **Origin settings**에서 **Use recommended origin settings**를 선택합니다.

26. **Cache settings**에서 **Use recommended cache settings tailored to serving S3 content**를 선택합니다.

27. [[Next]] 버튼을 클릭합니다.

### 2.3 Step 3: Enable security

28. **Do not enable security protections**를 선택합니다.

> [!NOTE]
> 이 실습에서는 WAF를 사용하지 않습니다. 프로덕션 환경에서는 보안 강화를 위해 WAF 활성화를 권장합니다.

29. [[Next]] 버튼을 클릭합니다.

### 2.4 Step 4: Get TLS certificate

30. 이 단계에서는 기본 설정을 그대로 사용합니다 (사용자 지정 도메인을 사용하지 않으므로 TLS 인증서 설정이 필요하지 않습니다).

31. [[Next]] 버튼을 클릭합니다.

### 2.5 Step 5: Review and create

32. 설정을 검토한 후 [[Create distribution]] 버튼을 클릭합니다.

> [!NOTE]
> CloudFront가 자동으로 OAC를 생성하고 S3 버킷 정책 업데이트를 안내하는 배너가 상단에 표시됩니다. 배포가 전 세계 엣지 로케이션에 전파되는 데 약 15-20분이 소요됩니다. **Last modified** 필드가 "Deploying"에서 날짜/시간으로 변경되면 배포가 완료된 것입니다.

✅ **태스크 완료**: CloudFront 배포가 생성되었습니다. 배포 전파를 기다리는 동안 태스크 3을 진행합니다.


## 태스크 3: Amazon S3 버킷 정책 업데이트

> [!NOTE]
> 이 단계에서 S3 버킷 정책을 업데이트하는 이유는 Amazon CloudFront OAC가 S3 버킷에 접근할 수 있도록 허용하기 위해서입니다. 정책을 적용하지 않으면 CloudFront가 S3에서 콘텐츠를 가져올 수 없어 "Access Denied" 오류가 발생합니다.

33. 배포 생성 후 상단에 나타나는 배너에서 [[Copy policy]] 버튼을 클릭하여 S3 버킷 정책을 복사합니다.

> [!TIP]
> 배너가 사라진 경우, 배포 상세 페이지의 **Origins** 탭에서 오리진을 선택하고 [[Edit]] 버튼을 클릭하면 정책을 다시 확인할 수 있습니다.

34. 상단 검색창에서 `S3`를 검색하고 **S3**를 선택합니다.

35. **cloudarchitect-lab-s3website-[계정ID]** 버킷을 선택합니다.

36. 상단 탭 중 **Permissions** 탭을 선택합니다.

37. **Bucket policy** 섹션에서 [[Edit]] 버튼을 클릭합니다.

38. 기존 정책을 모두 삭제하고 복사한 CloudFront OAC 정책을 붙여넣습니다.

39. [[Save changes]] 버튼을 클릭합니다.

> [!TIP]
> OAC 정책을 적용하면 S3 버킷에 직접 접근할 수 없고 CloudFront를 통해서만 콘텐츠에 접근할 수 있습니다. 이렇게 하면 S3 버킷을 퍼블릭으로 공개하지 않아도 웹사이트를 제공할 수 있어 보안이 강화됩니다.

✅ **태스크 완료**: S3 버킷 정책이 CloudFront OAC 정책으로 업데이트되었습니다.


## 태스크 4: 웹사이트 접근 테스트

40. Amazon CloudFront 콘솔로 이동하여 배포의 **Last modified** 필드가 날짜/시간으로 변경되었는지 확인합니다.

41. 배포 상세 페이지의 **General** 탭에서 **Distribution domain name**을 복사합니다 (예: `d111111abcdef8.cloudfront.net`).

42. 새 브라우저 탭을 열고 `https://[복사한 Domain name]/index.html`로 접속합니다.

43. 웹사이트가 정상적으로 로드되는지 확인합니다.

44. 브라우저 **개발자 도구**(F12)를 열고 **Network** 탭을 선택합니다.

45. 페이지를 새로고침하고 `index.html` 요청을 선택하여 응답 헤더를 확인합니다.

46. `X-Cache` 헤더 값을 확인합니다:
- 첫 번째 요청: `Miss from cloudfront` (엣지 로케이션에 캐시가 없어 오리진에서 가져옴)
- 이후 요청: `Hit from cloudfront` (엣지 로케이션의 캐시에서 응답)

47. 페이지를 여러 번 새로고침하여 `X-Cache` 값이 `Hit from cloudfront`로 변경되는지 확인합니다.

> [!OUTPUT]
> ```
> 응답 헤더 예시:
> X-Cache: Hit from cloudfront
> Via: 1.1 xxxxx.cloudfront.net (CloudFront)
> X-Amz-Cf-Pop: ICN54-C1  (서울 엣지 로케이션)
> ```

> [!NOTE]
> `X-Amz-Cf-Pop` 헤더는 응답을 처리한 엣지 로케이션을 나타냅니다. `ICN`은 서울(인천) 엣지 로케이션을 의미합니다. 사용자의 위치에 따라 가장 가까운 엣지 로케이션에서 캐시된 콘텐츠를 제공합니다.

✅ **태스크 완료**: CloudFront를 통해 S3 콘텐츠가 정상적으로 제공되고 캐싱이 동작합니다.


## 태스크 5: 캐시 무효화 실습

> [!NOTE]
> 캐시 무효화는 S3에 새 콘텐츠를 업로드했지만 CloudFront가 이전 캐시를 계속 제공할 때 사용합니다. 프로덕션 환경에서는 파일명에 버전을 포함하는 방식(예: `index.v2.html`)이 더 효율적이지만, 이 실습에서는 무효화 기능을 직접 체험합니다.

48. Amazon S3 콘솔에서 **cloudarchitect-lab-s3website-[계정ID]** 버킷을 선택합니다.

49. `index.html` 파일의 체크박스를 선택하고 [[Download]] 버튼을 클릭하여 로컬에 저장합니다.

50. 다운로드한 파일을 텍스트 편집기로 열고 내용을 수정합니다 (예: "Hello world!" → "Hello CloudFront!").

51. 수정한 파일을 S3 버킷에 다시 업로드합니다 ([[Upload]] 버튼 선택).

52. CloudFront 도메인으로 접근하여 변경사항이 즉시 반영되지 않는 것을 확인합니다 (캐시된 이전 콘텐츠가 표시됨).

> [!NOTE]
> CloudFront는 기본적으로 24시간 동안 콘텐츠를 캐시합니다. 즉시 업데이트를 반영하려면 캐시 무효화(Invalidation)를 수행해야 합니다.

53. Amazon CloudFront 콘솔에서 생성한 배포를 선택합니다.

54. 상단 탭 중 **Invalidations** 탭을 선택합니다.

55. [[Create invalidation]] 버튼을 클릭합니다.

56. **Object paths**에 `/index.html`을 입력합니다.

57. [[Create invalidation]] 버튼을 클릭합니다.

58. 무효화 상태가 "Completed"가 될 때까지 기다립니다 (약 1-2분 소요).

59. 웹사이트를 새로고침하여 변경사항이 반영되었는지 확인합니다 ("Hello CloudFront!" 표시).

> [!TIP]
> `/*`를 입력하면 모든 파일의 캐시를 한 번에 무효화할 수 있습니다. 단, 무효화 요청은 월 1,000건까지 무료이며 초과 시 건당 비용이 발생합니다.

✅ **태스크 완료**: 캐시 무효화를 통해 S3에 업데이트한 콘텐츠가 CloudFront에 즉시 반영되었습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

### 방법 1: CloudShell에서 정리 스크립트 실행

1. AWS Management Console 상단의 **CloudShell** 아이콘을 선택합니다.

2. 다음 명령어로 정리 스크립트를 실행합니다:

```bash
./cleanup-11-2.sh
```

3. 삭제 확인 메시지가 표시되면 `y`를 입력하여 진행합니다.

4. 스크립트가 다음 리소스를 자동으로 삭제합니다:
   - S3 버킷 내 객체 및 버킷

> [!NOTE]
> 실습 중 직접 생성한 CloudFront 배포는 스크립트로 삭제되지 않을 수 있습니다. 아래 수동 삭제 단계를 확인하세요.

### 방법 2: 수동 삭제 (스크립트 실행이 불가능한 경우)

> [!IMPORTANT]
> CloudFront 배포는 먼저 **비활성화(Disable)** 한 후에만 삭제할 수 있습니다. 비활성화에 약 5-10분이 소요됩니다.

#### 태스크 1: Amazon CloudFront 배포 삭제

1. 상단 검색창에서 `CloudFront`를 검색하고 **CloudFront**를 선택합니다.

2. 실습에서 생성한 배포를 선택합니다.

3. **Disable** 버튼을 클릭합니다.

4. 확인 대화 상자에서 [[Disable]]를 클릭합니다.

> [!NOTE]
> 배포 상태가 "Deploying"에서 "Disabled"로 변경될 때까지 약 5-10분이 소요됩니다. 상태가 변경된 후 다음 단계를 진행합니다.

5. 배포 상태가 "Disabled"로 변경되면 배포를 다시 선택합니다.

6. **Delete** 버튼을 클릭합니다.

7. 확인 대화 상자에서 [[Delete]]를 클릭합니다.

#### 태스크 2: Amazon S3 버킷 삭제

8. 상단 검색창에서 `S3`를 검색하고 **S3**를 선택합니다.

9. 실습에서 생성한 버킷 (**cloudarchitect-lab-s3website-***) 을 선택합니다.

10. [[Empty]] 버튼을 클릭하여 버킷 내 모든 객체를 삭제합니다.

11. 확인 필드에 `permanently delete`를 입력하고 [[Empty]]를 클릭합니다.

12. 버킷 목록으로 돌아가서 버킷을 다시 선택합니다.

13. [[Delete]] 버튼을 클릭합니다.

14. 확인 필드에 버킷 이름을 입력하고 [[Delete bucket]]을 클릭합니다.

#### 태스크 3: 최종 확인

15. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

16. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

17. 다음과 같이 검색 조건을 설정합니다:
   - **Regions**: `Asia Pacific (Seoul) ap-northeast-2`
   - **Resource types**: `All supported resource types`
   - **Tags**: Tag key에 `Name`을 선택하고, Tag value에 `CloudArchitect-Lab`을 입력합니다.

18. [[Search resources]]를 클릭합니다.

19. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

🌐
Amazon CloudFront CDN
전 세계 엣지 로케이션을 통해 콘텐츠를 빠르게 전송하는 CDN 서비스를 구성했습니다

🔒
OAC(Origin Access Control)
S3 버킷을 퍼블릭으로 공개하지 않고 CloudFront를 통해서만 접근하도록 보안을 강화했습니다

🔄
캐시 무효화
S3 콘텐츠 업데이트 후 Invalidation을 통해 엣지 로케이션의 캐시를 즉시 갱신했습니다
