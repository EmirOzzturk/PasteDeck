# PasteDeck

> macOS için hafif, hızlı clipboard yöneticisi. Kopyaladıklarınızı tutar, listeler, tekrar yapıştırmanızı sağlar.

![Platform](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.2-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Kurulum

```bash
git clone https://github.com/kullanici/PasteDeck.git
cd PasteDeck

# Debug build
bash build_app.sh

# Release build
bash build_app.sh release

# Çalıştır
open .build/PasteDeck.app
```

İlk açılışta `Cmd+Shift+V` kısayolu için **Accessibility izni** ister — izin verin.

## Kullanım

| Eylem | Nasıl |
|-------|-------|
| Panoyu aç | Menü bar ikonu `📋` veya `Cmd+Shift+V` |
| Clip seç ve yapıştır | ↑↓ ile gez, `Enter` — otomatik yapıştırır |
| Arama | Arama kutusuna yaz, anlık filtreler |
| Sabitle (pin) | Sağ tık → Pin / Hover'da 📌 simgesi |
| Sil | Sağ tık → Delete |
| Tümünü temizle | Alt kısımda "Clear All" (pin'li olanlar kalır) |
| Kapat | `Esc` veya pencere dışına tıkla |

**Özel:** HTML kopyaladığınızda sağ tık → **Copy Plain Text** ile sadece düz yazıyı alabilirsiniz.

## Özellikler

- 🚀 **Anlık** — 0.15 sn poll ile neredeyse gerçek zamanlı
- 🖼️ **Görsel desteği** — Kopyalanan görselleri thumbnail ile listeler
- 📌 **Pin** — Sık kullandıklarınız silinmez
- 🔍 **Anlık arama** — Geçmiş içinde filtreleme
- 🪟 **Konum hatırlama** — Pencereyi sürükleyin, yerini hatırlar
- ⌨️ **Tam klavye** — Aç, gez, seç, kapat — hepsi klavyeden
- 🧹 **Otomatik temizlik** — 50 üstü LRU, bozuk referansları otomatik siler

## Gereksinimler

- macOS 14 Sonoma veya üstü
- Swift 6.2

## Lisans

MIT — özgürce kullanın, fork'layın, dağıtın.
