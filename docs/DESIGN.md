# Vabu arayüz ilkeleri

Referans: [Pond tasarım rehberi](https://www.butterfly.so/pond/design).
Vabu kendi kimliğini korur. Rehberin yararlı bağlam, ölçülü yerleşim, uyumlu
bileşenler ve işlevi açıklayan hareket yaklaşımını uygular; marka varlıklarını kopyalamaz.

## Ortak kurallar

- Açıkta sıcak nötr zemin, koyuda opak kömür rengi. Tek vurgu rengi seçim,
  birincil eylem ve odak içindir. Dekoratif durum noktaları veya sahte ilerleme yoktur.
- Gövde metni 15 px, yardımcı metin en az 14 px. Hanken Grotesk; kodda JetBrains Mono.
  Kullanıcı yazı ölçeği korunur. Ayrıntılar gereksiz yere düşük opaklığa indirilmez.
- Giriş alanı seçilebilir, Tab ile erişilebilir, odaktayken belirgin çerçevelidir.
  Seçim yalnız renk değişimine dayanmaz: kutuda tik/çizgi, radyoda iç işaret görünür.
- Küçük ikonlar yerel font çizimini kullanır; dolgu ekseni kare başına değiştirilmez.
- Düğme basınca zıplamaz. Kabukta açılış 240 ms, kapanış 140 ms, durum 160 ms,
  hızlı geri bildirim 120 ms. Azaltılmış hareket bunları sıfırlar.
- Opak yüzey varsayılandır. İsteğe bağlı cam efekti kapalıyken duvar kâğıdı ve
  bulanıklık shader'ı oluşturulmaz. Bu bir kaynak kullanımı iyileştirmesidir;
  ölçülmüş FPS veya hızlanma katsayısı iddiası değildir.

## Calamares

Hesap oluşturma, disk seçimi ve doğrulama Calamares'in gerçek yerel kontrollerini
kullanır. Görsel özelleştirme QSS ve Qt Quick bileşenlerindedir; parola politikası,
kurulum işleri ve güvenlik sınırları değiştirilmez. `usersq` etkin değildir.

Etkileşimli sayfalar (karşılama, konum, klavye, disk, hesap, özet, bitiş) ve
alt gezinme yerel Qt Widgets kullanır. Qt 6 üzerinde gömülü QML pencerelerinde
klavye odağı gerçek giriş testinden geçmediği için bu yola bağımlı değildir.
Özel QSS teması tüm yerel kontrolleri, üst QML şeridi adım adı/sayacı ve Vabu
kimliğini, salt görüntü slaytı gerçek kurulum durumuna eşlik eden metni sağlar.
Alternatif QML sayfaları kaynakta korunur fakat etkin kurulum akışında kullanılmaz.

Sayfa girişinde kullanıcı alanlarını kaydıran animasyon yoktur. Kurulum
ilerlemesi Calamares'in gerçek iş durumundan gelir. Parola doğrulaması, kurulum
motoru ve güvenlik sınırları görsel tasarım değişikliğinden bağımsızdır.

Tikler, kısmi seçim, radyo ve oklar yerel SVG varlıklarıdır. QSS dosyasındaki
mutlak yollar ISO'daki `/etc/calamares/branding/vabu/assets/` dizinini gösterir.
CI yalnızca kopyalanmış test yapılandırmasında bu yolu fixture dizinine çevirir.

Calamares 3.3.14 hesap formu bazı durum ikonlarını mesaj etiketinin ölçüsüyle
esnetir. Bu dekoratif ikon etiketleri gizlenir; gerçek doğrulama ve tüm metin
hataları korunur. Bu bir Calamares kaynak yaması değildir.

## Doğrulama

- `tests/installer-input.py`: ayrılmış Wayland oturumunda gerçek fare/klavye,
  beş hesap alanı, farklı/eşleşen parola, tik açıp kapatma, 1024×768 görünüm,
  ileri/geri giderken değerlerin korunması. Ayrı senaryolarda hoş geldin sayfası,
  dil listesi, Tab/Space ile ilerleme ve bitiş sayfası çizilir.
- `tests/installer-style.py`: gerçek Qt Widgets çizimi, SVG geçerliliği,
  işaretlerin piksel kontrolü, seçim/pasif durumlar, radyo, liste ve sayı alanı.
- `tests/ekran.sh`: kabuk ekranları, açık/koyu görünüm, Türkçe/İngilizce,
  gerçek 800×600 pencere sınırı, %150 yazı, azaltılmış hareket ve yüksek kontrast.
  Uzun gezinme başlıkları sarılır; düğmeler dar alanda alt satıra geçer.
- `tests/grub-ekran.sh`: görsellerin 8 bit RGB/RGBA biçimi ve QEMU içinde
  gerçek temalı çizim zorunludur; temasız menü başarılı sayılmaz.
- RPM iş akışı: aarch64 ve x86_64 hesap/görünüm testleri, qmllint, çalışma
  zamanı QML derlemesi ve ekran görüntüleri.

Kurulum testleri `exec` adımı içermez; disk biçimlendirme veya hesap oluşturma
başlatamaz. Görsel CI gerçek ISO kurulumunun, gerçek GPU ölçümünün veya tüm
üçüncü taraf uygulamalardaki tema davranışının yerini tutmaz. Bunlar VM/donanım
kabul testlerinde ayrıca doğrulanır.
