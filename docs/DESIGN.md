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
- Düğme basınca zıplamaz. Kabukta açılış 240 ms, kapanış 140 ms, durum 160 ms,
  hızlı geri bildirim 120 ms. Azaltılmış hareket bunları sıfırlar.
- Opak yüzey varsayılandır. İsteğe bağlı cam efekti kapalıyken duvar kâğıdı ve
  bulanıklık shader'ı oluşturulmaz. Bu bir kaynak kullanımı iyileştirmesidir;
  ölçülmüş FPS veya hızlanma katsayısı iddiası değildir.

## Calamares

Hesap oluşturma, disk seçimi ve doğrulama Calamares'in gerçek yerel kontrollerini
kullanır. Görsel özelleştirme QSS ve Qt Quick bileşenlerindedir; parola politikası,
kurulum işleri ve güvenlik sınırları değiştirilmez. `usersq` etkin değildir.

Calamares 3.3.14'ün Qt 6 pencere kapsayıcısı varsayılan olarak klavye odağı
almaz. `QWindowContainer` için hedefli QSS odak politikası bunu düzeltir; pasif
etiketlerin odak davranışı değişmez. Bu Qt sınıfına bağımlılık gerçek klavye
regresyon testi ve Qt Widgets odak politikası kontrolüyle korunur.

Düğmeler ortak `VabuButton.qml` ile fare, klavye ve erişilebilirlik davranışını
korur. Üstte adım adı ve sayı, altta tutarlı gezinme yer alır. Sayfa girişindeki
kayma kaldırılmıştır; kullanıcı yazarken form hareket etmez. Kurulum ilerlemesi
Calamares'in gerçek iş durumundan gelir.

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
  dar pencere, %150 yazı, azaltılmış hareket ve yüksek kontrast.
- RPM iş akışı: aarch64 ve x86_64 hesap/görünüm testleri, qmllint, çalışma
  zamanı QML derlemesi ve ekran görüntüleri.

Kurulum testleri `exec` adımı içermez; disk biçimlendirme veya hesap oluşturma
başlatamaz. Görsel CI gerçek ISO kurulumunun, gerçek GPU ölçümünün veya tüm
üçüncü taraf uygulamalardaki tema davranışının yerini tutmaz. Bunlar VM/donanım
kabul testlerinde ayrıca doğrulanır.
