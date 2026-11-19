# Lab 7: Triển khai CI Pipeline với Jenkins, Maven, Nexus & SonarQube

**Sinh viên thực hiện:** Ma Quốc Đan  
**MSSV:** DTC235180041  
**Môn học:** DevOps  
**Repository:** [https://github.com/quocdan31/devops-lab7-ci-demo](https://github.com/quocdan31/devops-lab7-ci-demo)

---

## 1. Mục tiêu Lab

1. Dựng hệ thống CI Server gồm **Jenkins**, **Nexus Repository OSS**, và **SonarQube** bằng Docker Compose.
2. Xây dựng Declarative Pipeline hoàn chỉnh qua `Jenkinsfile`:
   - **Checkout**: Kéo mã nguồn từ GitHub.
   - **Build**: Biên dịch mã nguồn ứng dụng Java với Maven (`mvn clean compile`).
   - **Test**: Thực thi 6 unit tests với JUnit 5 (`mvn test`), lưu trữ báo cáo XML qua Surefire.
   - **SonarQube Analysis**: Phân tích mã nguồn tĩnh (SAST) tự động với `sonar-maven-plugin`.
   - **Package**: Đóng gói artifact `.jar` (`mvn package -DskipTests`) và lưu trữ (archive).
   - **Publish to Nexus**: Đẩy gói artifact (`ci-demo-1.0.0-SNAPSHOT.jar`) lên kho lưu trữ Maven Snapshots trên Nexus.
3. Cấu hình tự động kích hoạt pipeline (GitHub Webhook / SCM Polling).

---

## 2. Kiến trúc CI Pipeline

```text
+---------------+        +--------------------------------------------------------+
| GitHub Repo   | -----> | Jenkins CI Pipeline (Declarative)                     |
| (quocdan31/   | Webhook| 1. Checkout SCM                                       |
|  devops-lab7) |        | 2. Build (mvn clean compile)                          |
+---------------+        | 3. Test (mvn test + JUnit reports)                    |
                         | 4. Static Code Analysis (SonarQube Scanner) --------->| +----------------+
                         | 5. Package (.jar artifact)                            | | SonarQube      |
                         | 6. Publish Artifact -------------------------------->| | (Port 9000)    |
                         +--------------------------------------------------------+ +----------------+
                                                                                            |
                                                                                            v
                                                                                   +----------------+
                                                                                   | Nexus OSS      |
                                                                                   | (Port 8081)    |
                                                                                   +----------------+
```

---

## 3. Cấu trúc Thư mục

```text
d:\lap7\
├── docker-compose.yml              # Dựng 3 services: Jenkins, Nexus, SonarQube
├── Jenkinsfile                     # Declarative Pipeline chuẩn 6 stages
├── settings.xml                    # Cấu hình credentials xác thực Maven tới Nexus
├── ho_ten_mssv.txt                 # Thông tin sinh viên nộp bài
├── Lab7_Report.md                  # Báo cáo chi tiết quá trình thực hiện Lab
├── README.md                       # Tài liệu hướng dẫn & giải trình
├── configs/                        # Thư mục lưu cấu hình dự phòng
│   ├── docker-compose.yml
│   ├── Jenkinsfile
│   └── settings.xml
├── scripts/                        # Scripts tự động hóa
│   ├── setup.ps1 / setup.sh        # Khởi động Docker stack & lấy admin password
│   ├── verify.ps1 / verify.sh      # Kiểm tra containers & endpoint status
│   └── cleanup.ps1 / cleanup.sh    # Dọn dẹp containers khi hoàn thành
└── sample-java-app/                # Ứng dụng mẫu Java Maven
    ├── Jenkinsfile                 # Script pipeline đặt cùng source code
    ├── pom.xml                     # Cấu hình Maven, JUnit 5, Surefire, Sonar plugin
    └── src/
        ├── main/java/com/devops/lab7/
        │   └── Calculator.java     # Logic tính toán mẫu (add, sub, mul, div, isPositive)
        └── test/java/com/devops/lab7/
            └── CalculatorTest.java # 6 Unit tests kiểm thử Calculator
```

---

## 4. Hướng dẫn Triển khai Từng bước

### Bước 1: Khởi động Hạ tầng Docker (Jenkins + Nexus + SonarQube)

Chạy script khởi động:
```powershell
.\scripts\setup.ps1
```
Hoặc dùng lệnh Docker Compose:
```bash
docker compose up -d
```

Các dịch vụ sẽ lắng nghe tại:
- **Jenkins:** [http://localhost:8080](http://localhost:8080)
- **Nexus Repository:** [http://localhost:8081](http://localhost:8081)
- **SonarQube:** [http://localhost:9000](http://localhost:9000)

Lấy mật khẩu khởi tạo:
```bash
# Jenkins
docker exec lab7-jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Nexus
docker exec lab7-nexus cat /nexus-data/admin.password
```

---

### Bước 2: Cấu hình Công cụ & Credentials trong Jenkins

1. **Cài đặt Plugins cần thiết:**
   - *Pipeline: Stage View*
   - *SonarQube Scanner*
   - *Nexus Artifact Uploader*
   - *Config File Provider*

2. **Cấu hình Global Tools (Manage Jenkins → Tools):**
   - **JDK:** Name `JDK21` → JAVA_HOME: `/opt/java/openjdk` (hoặc cài đặt tự động)
   - **Maven:** Name `M3` → Tích *Install automatically* → Version `3.9.x`

3. **Cấu hình Credentials (Manage Jenkins → Credentials):**
   - **SonarQube Token:** Kind `Secret text`, ID: `sonarqube-token`
   - **Nexus Credentials:** Kind `Username with password`, ID: `nexus-credentials`, Username: `admin`, Password: `<nexus_password>`

4. **Cấu hình Managed Files (Config File Provider):**
   - Tạo file `Maven settings.xml` với ID: `maven-settings-nexus` chứa server ID `nexus` map với `${env.NEXUS_USERNAME}` và `${env.NEXUS_PASSWORD}`.

---

### Bước 3: Cấu hình Nexus Repository

1. Đăng nhập [http://localhost:8081](http://localhost:8081).
2. Vào **Settings → Repositories → Create repository**.
3. Chọn kiểu: **maven2 (hosted)**.
4. Đặt tên: `maven-snapshots`, Version policy: `Snapshot`.

---

### Bước 4: Kiểm thử Ứng dụng Local với Maven

Tại thư mục `sample-java-app/`:
```bash
mvn clean test
```
**Kết quả kiểm thử:**
```text
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.devops.lab7.CalculatorTest
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.167 s
[INFO] 
[INFO] Results:
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
```

Đóng gói file `.jar`:
```bash
mvn clean package
# File tạo tại: target/ci-demo-1.0.0-SNAPSHOT.jar
```

---

### Bước 5: Cấu hình Jenkins Pipeline Job

1. Vào Jenkins Dashboard → **New Item** → Tên: `DevOps-Lab7-CI-Pipeline` → Chọn **Pipeline**.
2. Phần **Pipeline Definition**:
   - **Definition:** `Pipeline script from SCM`
   - **SCM:** `Git`
   - **Repository URL:** `https://github.com/quocdan31/devops-lab7-ci-demo.git`
   - **Branch Specifier:** `*/main`
   - **Script Path:** `sample-java-app/Jenkinsfile` (hoặc `Jenkinsfile`)
3. **Build Triggers:** Tích chọn `GitHub hook trigger for GITScm polling` hoặc thiết lập Poll SCM `H/5 * * * *`.
4. Nhấn **Save** và chọn **Build Now**.

---

### Bước 6: Kiểm tra Kết quả Pipeline

Khi pipeline thực thi thành công:
1. **Pipeline Stage View:** Cả 6 giai đoạn (`Checkout`, `Build`, `Test`, `SonarQube Analysis`, `Package`, `Publish to Nexus`) đều hiển thị trạng thái xanh (SUCCESS).
2. **Artifacts:** File `ci-demo-1.0.0-SNAPSHOT.jar` được lưu trữ trực tiếp trong Jenkins build artifacts.
3. **Nexus:** Kiểm tra repository `maven-snapshots` tại đường dẫn `com/devops/lab7/ci-demo/1.0.0-SNAPSHOT/` xuất hiện file `.jar`.
4. **SonarQube:** Dự án `devops-lab7` được cập nhật chỉ số chất lượng mã nguồn (Quality Gate: Passed, 0 Bugs, 0 Vulnerabilities).

---

### Bước 7: Dọn dẹp Tài nguyên

Khi hoàn thành buổi thực hành:
```powershell
.\scripts\cleanup.ps1
# hoặc: docker compose down
```
