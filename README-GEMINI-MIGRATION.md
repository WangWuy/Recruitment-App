# 🔐 Gemini API Key Migration - Tổng hợp

## 📌 Vấn đề

Bạn đang có API key của Gemini được hardcode trong Flutter app:
```dart
// lib/services/gemini_service.dart
static const String _apiKey = 'AIzaSy...YOUR_KEY_HERE'; // ❌ NGUY HIỂM!
```

**Đây là lỗ hổng bảo mật nghiêm trọng!**

## 🎯 Giải pháp

Di chuyển API key sang backend PHP để bảo mật.

## 📊 So sánh kiến trúc

### ❌ Hiện tại (Không an toàn)
```
Flutter App (có API key) → Gemini API
```
- API key bị lộ trong APK/IPA
- Ai cũng có thể decompile và lấy key
- Không kiểm soát được usage

### ✅ Đề xuất (An toàn)
```
Flutter App → Backend PHP (có API key) → Gemini API
```
- API key an toàn trên server
- Kiểm soát hoàn toàn
- Dễ dàng thay đổi

## 📚 Tài liệu đã chuẩn bị

### 1. **API-KEY-PLACEMENT-GUIDE.md** ⭐ BẮT ĐẦU TỪ ĐÂY
   - Giải thích chi tiết tại sao cần di chuyển
   - So sánh ưu/nhược điểm
   - Câu hỏi thường gặp

### 2. **CHECKLIST-GEMINI-MIGRATION.md** ✅ HƯỚNG DẪN TỪNG BƯỚC
   - Checklist đầy đủ từ A-Z
   - Các bước cụ thể để thực hiện
   - Troubleshooting

### 3. **MIGRATION-GEMINI-TO-BACKEND.md** 🔧 CHI TIẾT KỸ THUẬT
   - Hướng dẫn migration chi tiết
   - Code examples
   - Testing procedures

### 4. Backend Documentation
   - `/Applications/MAMP/htdocs/backend_php_api/README-GEMINI.md`
   - API endpoints documentation
   - Backend setup guide

## 🚀 Quick Start (10 phút)

### Bước 1: Backend (2 phút)
```bash
# Thêm API key vào .env
echo "GEMINI_API_KEY=AIzaSy...YOUR_ACTUAL_KEY_HERE" >> /Applications/MAMP/htdocs/backend_php_api/.env

# Restart MAMP
```

### Bước 2: Test Backend (1 phút)
```bash
curl -X POST http://localhost:9090/api/gemini/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Xin chào"}'
```

### Bước 3: Flutter (3 phút)
```bash
cd /Users/huynhquanghuy/recruitment_app

# Backup và thay thế
mv lib/services/gemini_service.dart lib/services/gemini_service.dart.backup
mv lib/services/gemini_service_backend.dart lib/services/gemini_service.dart

# Cập nhật baseUrl trong file (dòng 9)
# Android: http://10.0.2.2:9090
# iOS: http://localhost:9090
```

### Bước 4: Test App (2 phút)
```bash
flutter run
# Test chatbot trong app
```

### Bước 5: Cleanup (2 phút)
```bash
# Xóa backup
rm lib/services/gemini_service.dart.backup

# Commit
git add .
git commit -m "Security: Move Gemini API key to backend"
```

## 📁 Files đã tạo

### Backend:
- ✅ `controllers/GeminiController.php` - Controller xử lý Gemini API
- ✅ `README-GEMINI.md` - Documentation
- ✅ `test-gemini-api.sh` - Test script
- ✅ `.env.example` - Đã thêm GEMINI_API_KEY

### Flutter:
- ✅ `lib/services/gemini_service_backend.dart` - Service mới
- ✅ `API-KEY-PLACEMENT-GUIDE.md` - Hướng dẫn tổng quan
- ✅ `CHECKLIST-GEMINI-MIGRATION.md` - Checklist chi tiết
- ✅ `MIGRATION-GEMINI-TO-BACKEND.md` - Migration guide
- ✅ `README-GEMINI-MIGRATION.md` - File này

## 🎓 Đọc theo thứ tự

1. **Đầu tiên:** `API-KEY-PLACEMENT-GUIDE.md`
   - Hiểu vấn đề và giải pháp
   
2. **Sau đó:** `CHECKLIST-GEMINI-MIGRATION.md`
   - Follow từng bước
   
3. **Nếu cần chi tiết:** `MIGRATION-GEMINI-TO-BACKEND.md`
   - Đọc thêm về kỹ thuật

4. **Backend docs:** `/Applications/MAMP/htdocs/backend_php_api/README-GEMINI.md`
   - API endpoints reference

## ⚡ API Endpoints

Backend đã có sẵn 4 endpoints:

1. **POST /api/gemini/chat**
   - Chat với AI
   
2. **POST /api/gemini/job-recommendations**
   - Gợi ý công việc phù hợp
   
3. **POST /api/gemini/cv-suggestions**
   - Đánh giá và cải thiện CV
   
4. **POST /api/gemini/interview-prep**
   - Chuẩn bị phỏng vấn

## 🔒 Security Best Practices

### Ngay lập tức:
- ✅ Di chuyển API key sang backend
- ✅ Xóa API key khỏi Flutter

### Sau migration:
- ✅ Revoke API key cũ
- ✅ Tạo key mới
- ✅ Cập nhật vào `.env`

### Lâu dài:
- ✅ Thêm authentication
- ✅ Rate limiting
- ✅ Monitor usage
- ✅ Rotate keys định kỳ

## ❓ Câu hỏi thường gặp

### Q: Có chậm hơn không?
**A:** Chậm ~50-100ms, không đáng kể so với lợi ích bảo mật.

### Q: Có tốn thêm tiền không?
**A:** Không đáng kể, backend chỉ forward request.

### Q: Có phải sửa nhiều code không?
**A:** Không! Chỉ cần đổi file service, interface giống hệt.

### Q: Backend down thì sao?
**A:** Có thể implement fallback. Nhưng app cũng cần backend cho các API khác.

## 🆘 Hỗ trợ

Nếu gặp vấn đề:

1. **Kiểm tra logs:**
   ```bash
   tail -f /Applications/MAMP/htdocs/backend_php_api/logs/requests.log
   ```

2. **Test endpoint:**
   ```bash
   cd /Applications/MAMP/htdocs/backend_php_api
   ./test-gemini-api.sh
   ```

3. **Common issues:**
   - Connection refused → Backend chưa chạy
   - API key not configured → Chưa thêm vào `.env`
   - CORS error → Kiểm tra headers

## ✅ Checklist tổng quan

- [ ] Đã đọc `API-KEY-PLACEMENT-GUIDE.md`
- [ ] Đã thêm API key vào backend `.env`
- [ ] Đã test backend endpoint
- [ ] Đã cập nhật Flutter service
- [ ] Đã test Flutter app
- [ ] Đã xóa API key khỏi Flutter code
- [ ] Đã commit changes
- [ ] Đã revoke API key cũ (khuyến nghị)

## 🎉 Kết luận

**Migration này rất quan trọng cho bảo mật!**

Thời gian: ~10 phút
Lợi ích: Vô giá

Hãy làm ngay hôm nay! 🚀

---

**Tài liệu được tạo tự động bởi Antigravity AI Assistant**
**Ngày: 2025-12-10**
