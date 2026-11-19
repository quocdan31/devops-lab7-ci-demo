# BÁO CÁO THỰC HÀNH LAB 7: TRIỂN KHAI CI PIPELINE VỚI JENKINS, NEXUS & SONARQUBE

**Học phần:** Thực hành DevOps  
**Sinh viên thực hiện:** Ma Quốc Đan  
**Mã số sinh viên (MSSV):** DTC235180041  
**GitHub Repository:** [https://github.com/quocdan31/devops-lab7-ci-demo](https://github.com/quocdan31/devops-lab7-ci-demo)  
**Thời gian hoàn thành:** 19/11/2026  

---

## 1. MỤC TIÊU VÀ Ý NGHĨA CỦA LAB

Continuous Integration (CI) là nền tảng cốt lõi trong quy trình phát triển phần mềm hiện đại, giúp tích hợp mã nguồn liên tục, phát hiện sớm các lỗi cú pháp, logic, lỗ hổng bảo mật và tự động hóa toàn bộ quá trình đóng gói và lưu trữ artifact.

Trong bài Lab 7, mục tiêu bao gồm:
1. Triển khai kiến trúc hạ tầng CI hoàn chỉnh gồm 3 thành phần chính:
   - **Jenkins CI:** Điều phối và thực thi tự động pipeline.
   - **Nexus Repository OSS:** Quản lý và lưu trữ artifact nhị phân (Binary Repository Manager).
   - **SonarQube Server:** Phân tích mã nguồn tĩnh (SAST), kiểm tra quy chuẩn mã nguồn và đánh giá Quality Gate.
2. Thiết kế và kiểm chứng ứng dụng Java chuẩn Maven (`ci-demo`) đi kèm bộ kiểm thử đơn vị JUnit 5.
3. Xây dựng kịch bản Declarative Pipeline (`Jenkinsfile`) gồm 6 giai đoạn chuẩn: **Checkout → Build → Test → SonarQube Scan → Package → Publish to Nexus**.
4. Cấu hình xác thực an toàn thông qua Jenkins Credentials và Managed Files.

---

## 2. KIẾN TRÚC HỆ THỐNG VÀ CÁC THÀNH PHẦN

### 2.1 Sơ đồ Kiến trúc

```text
  [ Developer Push ]
          │
          ▼
   [ GitHub Repo ] ──(Webhook / Polling)──▶ [ Jenkins Master ]
                                                   │
                   ┌───────────────────────────────┴───────────────────────────────┐
                   ▼                               ▼                               ▼
          [ Giai đoạn 1-3 ]               [ Giai đoạn 4 ]                 [ Giai đoạn 5-6 ]
        • Checkout SCM                  • SonarQube Scanner             • Package (.jar)
        • mvn clean compile             • Static Code Analysis          • Deploy to Nexus
        • mvn test (JUnit 5)            • Quality Gate Check            • Archive Artifacts
                   │                               │                               │
                   ▼                               ▼                               ▼
          [ Surefire XML ]                [ SonarQube Server ]           [ Nexus Repository ]
          (Test Reports)                     (Port 9000)                     (Port 8081)
```

### 2.2 Đặc tả các Dịch vụ Container

| Dịch vụ | Container Name | Image | Port | Vai trò trong hệ thống |
|---|---|---|---|---|
| **Jenkins** | `lab7-jenkins` | `jenkins/jenkins:lts-jdk21` | 8080 (UI), 50000 (Agent) | CI Controller thực thi các build stages |
| **Nexus 3** | `lab7-nexus` | `sonatype/nexus3:latest` | 8081 (UI), 8082 (Docker Reg) | Kho lưu trữ artifact Maven (`maven-snapshots`) |
| **SonarQube** | `lab7-sonarqube` | `sonarqube:lts-community` | 9000 (UI) | Máy chủ phân tích chất lượng & bảo mật mã nguồn |

Tất cả container được kết nối trong cùng bridge network `ci-network` để đảm bảo Jenkins giao tiếp trực tiếp với Nexus (`http://lab7-nexus:8081`) và SonarQube (`http://lab7-sonarqube:9000`) qua tên định danh nội bộ.

---

## 3. CHI TIẾT ỨNG DỤNG MẪU VÀ BỘ KIỂM THỬ (SAMPLE JAVA APP)

Ứng dụng mẫu `ci-demo` được phát triển theo cấu trúc chuẩn Maven, sử dụng Java 17/21 và JUnit 5:

### 3.1 Cấu trúc mã nguồn

- **`pom.xml`**: Khai báo dependencies `junit-jupiter-api` và `junit-jupiter-engine` phiên bản `5.10.2`, tích hợp `maven-surefire-plugin` (v3.2.5), `maven-jar-plugin` (v3.3.0) và `sonar-maven-plugin` (v5.1.0.4751).
- **`Calculator.java`**: Cung cấp các phương thức tính toán số học cơ bản:
  - `add(int a, int b)`
  - `subtract(int a, int b)`
  - `multiply(int a, int b)`
  - `divide(int a, int b)` (ném ngoại lệ `IllegalArgumentException` khi chia cho 0)
  - `isPositive(int number)`

### 3.2 Bộ kiểm thử đơn vị (`CalculatorTest.java`)

Bao gồm 6 ca kiểm thử bao phủ toàn bộ các phương thức nghiệp vụ:
1. `testAdd`: Kiểm thử cộng số dương, số âm và số 0.
2. `testSubtract`: Kiểm thử phép trừ thông thường và cho kết quả âm.
3. `testMultiply`: Kiểm thử nhân với số dương, số 0 và số âm.
4. `testDivide`: Kiểm thử phép chia cho kết quả chẵn và số thập phân.
5. `testDivideByZero`: Kiểm thử bắt ngoại lệ `IllegalArgumentException` khi số chia bằng 0 (`assertThrows`).
6. `testIsPositive`: Kiểm thử logic nhận diện số dương (> 0) và các trường hợp biên (0, số âm).

**Kết quả chạy thực tế trên môi trường:**
```text
-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running com.devops.lab7.CalculatorTest
Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.167 s -- in com.devops.lab7.CalculatorTest

Results:
Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

---

## 4. PHÂN TÍCH CÁC GIAI ĐOẠN TRONG JENKINSFILE

Kịch bản Declarative Pipeline trong file `Jenkinsfile` được chuẩn hóa thành 6 stages:

### Stage 1: Checkout
- **Nhiệm vụ:** Kết nối tới Git SCM (`quocdan31/devops-lab7-ci-demo`) trên nhánh `main`, tải phiên bản mã nguồn mới nhất vào workspace của Jenkins.
- **Lệnh:** `checkout scm`.

### Stage 2: Build
- **Nhiệm vụ:** Biên dịch mã nguồn Java thành các file bytecode `.class` trong thư mục `target/classes`.
- **Lệnh:** `sh 'mvn clean compile'` (trong ngữ cảnh thư mục `sample-java-app`).

### Stage 3: Test
- **Nhiệm vụ:** Thực thi toàn bộ unit tests bằng Maven Surefire. Báo cáo kết quả được ghi nhận và xuất ra định dạng XML tại `target/surefire-reports/*.xml`.
- **Post Action:** Stage sử dụng block `junit 'target/surefire-reports/*.xml'` để tích hợp trực tiếp biểu đồ kết quả test vào giao diện Jenkins Dashboard.

### Stage 4: SonarQube Analysis
- **Nhiệm vụ:** Phân tích mã nguồn tĩnh, kiểm tra Code Smells, Bugs, Security Hotspots và đo lường độ phức tạp mã nguồn (Cyclomatic Complexity).
- **Cơ chế an toàn:** Sử dụng `withSonarQubeEnv('SonarQube')` và inject token xác thực qua `withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')])`.
- **Lệnh:**
  ```bash
  mvn sonar:sonar \
      -Dsonar.projectKey=devops-lab7 \
      -Dsonar.projectName="DevOps Lab 7 CI Demo" \
      -Dsonar.token="$SONAR_TOKEN"
  ```

### Stage 5: Package
- **Nhiệm vụ:** Đóng gói toàn bộ mã nguồn đã biên dịch thành gói nhị phân độc lập `ci-demo-1.0.0-SNAPSHOT.jar`.
- **Lệnh:** `mvn package -DskipTests` (bỏ qua test vì đã chạy ở stage trước để tối ưu thời gian).
- **Archive:** Kích hoạt chỉ thị `archiveArtifacts artifacts: 'target/*.jar', fingerprint: true` để lưu trữ artifact trực tiếp trên Jenkins Master.

### Stage 6: Publish to Nexus
- **Nhiệm vụ:** Đẩy gói artifact đã đóng gói lên kho lưu trữ Maven Snapshots trên máy chủ Nexus OSS.
- **Cơ chế bảo mật:** Sử dụng `withCredentials` để truyền tài khoản Nexus và `configFileProvider` để inject file cấu hình xác thực Maven (`settings.xml`).
- **Lệnh:**
  ```bash
  mvn deploy:deploy-file \
      -s "$MAVEN_SETTINGS" \
      -DgroupId=com.devops.lab7 \
      -DartifactId=ci-demo \
      -Dversion=1.0.0-SNAPSHOT \
      -Dpackaging=jar \
      -Dfile=target/ci-demo-1.0.0-SNAPSHOT.jar \
      -Durl=http://lab7-nexus:8081/repository/maven-snapshots/ \
      -DrepositoryId=nexus
  ```

---

## 5. TỔNG KẾT VÀ BÀI HỌC KINH NGHIỆM

1. **Tính độc lập và bảo mật của Pipeline:** Không lưu mật khẩu hoặc token trực tiếp (hardcode) trong source code hay Jenkinsfile. Tất cả thông tin nhạy cảm phải được quản lý qua Jenkins Credentials Manager và config file provider.
2. **Quản lý Artifact tập trung với Nexus:** Việc tách rời build server (Jenkins) và repository manager (Nexus) giúp phân tách trách nhiệm rõ ràng. Các artifact có phiên bản rõ ràng (Semantic Versioning) cho phép các hệ thống khác (hoặc môi trường staging/production) tải về và deploy đồng nhất mà không cần build lại từ đầu.
3. **Chất lượng mã nguồn liên tục với SonarQube:** Việc tích hợp SAST vào pipeline ngăn chặn mã nguồn kém chất lượng hoặc chứa lỗi bảo mật nghiêm trọng vượt qua Quality Gate trước khi đóng gói thành sản phẩm.
4. **Tự động hóa hoàn toàn:** Sự kết hợp giữa Git Webhook/Polling và Jenkins Pipeline tạo ra chu trình phản hồi tức thì (Fast Feedback Loop) cho đội ngũ phát triển ngay khi có commit mới.
