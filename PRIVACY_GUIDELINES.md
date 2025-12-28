# App Store Privacy Section Doldurma Talimatları

## KurekTrack - Privacy Information for App Store

### Kategori: Health & Fitness

#### Privacy Section - Veri Toplama

**1. Location**
- ✅ Var - GPS konum takibi
- Linked to user: NO
- Tracking: NO
- Purpose: App Functionality (antrenman mesafesi ve harita)

**2. Health**
- ✅ Var - Kalori, antrenman metriksleri
- Linked to user: NO
- Tracking: NO
- Purpose: App Functionality

**3. User ID**
- ✅ Var - Antrenman ID'leri (yerel)
- Linked to user: NO
- Tracking: NO
- Purpose: App Functionality

**4. Product Interaction**
- ✅ Var - Uygulama kullanımı istatistikleri
- Linked to user: NO
- Tracking: NO
- Purpose: App Functionality

---

## App Store Connect'te Doldurulması Gereken Alanlar

### 1. App Privacy
**Soruları Yanıtla:**
- "Do you or your partners collect user data?" → YES
- Select data types:
  - [x] Location
  - [x] Health & fitness
  - [x] User IDs
  - [x] App interaction data

### 2. Data Collection & Privacy Practices

**Location Data**
- Purpose: App Functionality
- Linked to user: No
- Used for tracking: No

**Health & Fitness Data**
- Purpose: App Functionality
- Linked to user: No
- Used for tracking: No

**User IDs**
- Purpose: App Functionality
- Linked to user: No
- Used for tracking: No

**Product Interaction Data**
- Purpose: App Functionality
- Linked to user: No
- Used for tracking: No

### 3. Contact Information
- Privacy Policy URL: (Gerekli - Privacy Policy'nin web linki)
- Support Email: [Your Support Email]

### 4. Age-Appropriate Content
- Age Rating: 4+
- Content Rating: None needed

### 5. Encryption
- ✅ Data in transit is encrypted
- ✅ Data at rest is encrypted

### 6. Server Information
- Server Location: On-device (no server transmission)
- Third-party services: Optional weather API (user's choice)

---

## Türkçe Açıklama - App Store Türkiye'ye Yönelik

### Gizlilik & Güvenlik

**Toplanan Veriler:**
- 📍 Konum (GPS) - Antrenman takibi için
- 💪 Sağlık Verileri - Kalori ve performans metriksleri
- 🏷️ Uygulama Kimlikleri - Antrenman geçmişi
- 📊 Uygulama Etkileşimi - Kullanım istatistikleri

**Verilerin İşlenmesi:**
- Tüm veriler cihazda yerel olarak işlenir
- Harici sunuculara iletilmez
- Tamamen kullanıcı kontrolü altında

**Şifreleme:**
- ✅ Aktarım sırasında şifreleme
- ✅ Depolamada şifreleme
- ✅ SSL/TLS güvenli bağlantı

---

## Checklist - App Store'a Yüklemeden Önce

- [x] Privacy Policy hazırlandı
- [x] PrivacyInfo.xcprivacy oluşturuldu
- [ ] App Store Connect'te Privacy section dolduruldu
- [ ] Privacy Policy web linklenecek (hosting gerekli)
- [ ] Info.plist permissionlar eklenecek
- [ ] Privacy Policy'nin Türkçe versiyonu hazırlandı
- [ ] Legal review yapıldı (opsiyonel)

---

## Not

Bu bilgiler KurekTrack uygulamasının mevcut yapısına dayanmaktadır:
- Yerel veri depolama
- İsteğe bağlı hava durumu servisi
- Konum, ses ve sağlık verileri

Apple'ın privacy gereklilikleri zaman zaman değişebilir. En güncel bilgiler için:
https://developer.apple.com/app-store/review/privacy-requirements/
