# ISO üretimi için gerekenler

Bu belge hazırlıktır; bu çalışma ISO üretmez veya GitHub workflow başlatmaz.

## Bu çalışmada okunan mevcut durum

- Depo `ii-las/vabu`, public; varsayılan dal `main`.
- GitHub'da `COPR_CONFIG` adlı secret mevcut. Yalnızca adı okundu; değeri alınmadı. Yeniden paylaşma veya bu sohbete yapıştırma.
- Repository variables listesi boş: `COPR_KEY_SHA256` henüz tanımlı değil.
- Son RPM işleri arasında başarılı işler var; bunlar bu yerel Codex değişikliklerinin derlendiği anlamına gelmez.
- Kaynak `COPR_OWNER` dosyası `ii-las`, proje adı `vabu`, Fedora `45` diyor. Gerçek COPR hesabındaki projenin bunlarla aynı olduğunu doğrulamak gerekir.
- Bu Mac `arm64`; aynı mimarideki VM için ISO hedefi `aarch64` olur. x86_64 ayrıca üretilebilir; bu başka mimaridir.

## Kullanıcının hazırlayacağı açık bilgiler

1. [COPR projesini](https://copr.fedorainfracloud.org/coprs/ii-las/vabu/) hesabında aç; bunun gerçekten kullandığın proje olduğunu doğrula. Projen farklıysa yalnızca doğru proje bağlantısını gönder. Mevcut kodda owner değiştirilebilir ama proje adı `vabu` olarak tanımlıdır; farklı isim varsa birlikte uyarlanmalıdır.
2. Projenin açık imza anahtarı/parmak izini güvenilen COPR proje yönetimi ekranından veya daha önce güvenilir biçimde kaydettiğin kayıttan doğrula. Açık anahtar herkese açıktır; özel anahtar/API token değildir. Aynı indirme dosyasının özetini hesaplamak tek başına kimliği kanıtlamaz.
3. Aşağıdaki yardımcı public key'i yalnızca bellekte okur; dosya kaydetmez, GPG'ye anahtar yüklemez, paket kurmaz ve GitHub ayarı yapmaz. Bu çalışmada `--fetch` çalıştırılmadı; testler yapay anahtar baytlarıyla yapıldı.

```sh
python3 "/Users/salihgokce/Documents/VabuDistro-Codex/tools/copr-key-info.py" --fetch
```

Çıktıda `publicKeyFingerprint` ve `fileSHA256` vardır. İlkini güvenilen proje parmak iziyle karşılaştır. İstersen bağımsız doğruladığın parmak izini komuta `--expected-fingerprint "PARMAK_IZI"` ile ver; uyuşmazsa araç hata verir. SHA-256 değeri dosyanın özgün baytlarından hesaplanır. Boş/HTML/özel anahtar, kesilmiş paket veya desteklenmeyen OpenPGP biçimleri reddedilir. Yardımcı mevcut yaygın OpenPGP v4 anahtarlarını inceler; bu bir tam imza veya anahtar sahipliği doğrulayıcısı değildir.

4. [GitHub Actions değişkenlerine](https://github.com/ii-las/vabu/settings/variables/actions) gir: **Settings → Secrets and variables → Actions → Variables → New repository variable**.

| Alan | Yazılacak değer |
|---|---|
| Name | `COPR_KEY_SHA256` |
| Value | Doğru açık anahtara ait doğruladığın `fileSHA256` alanındaki 64 haneli değer |

Normal tercih **variable** kullanmaktır. `COPR_KEY_SHA256` değerini zaten Secret olarak eklediysen akış bunu da kabul eder; değeri taşımana gerek yok. İkisi birden varsa Variable önceliklidir. `COPR_CONFIG` secret'ına dokunma. Buraya parmak izi, URL veya anahtarın tamamı yazılmaz. `fileSHA256` ile OpenPGP parmak izi farklı değerlerdir.

Bana yalnızca doğru COPR proje bağlantısı, doğrulanmış açık parmak izi/özet veya değişkeni eklediğin bilgisi gerekir. Parola, özel anahtar, COPR API secret, GitHub token veya disk şifresi gönderme.

## Sonraki adımların sırası

- Kaynak değişiklikleri incelenip GitHub'da derlenecek dala aktarılmalı. Ana dala birleştirme gerekmeden, seçilen dalda elle RPM workflow'u `publish_copr=true` ve `copr_arch=aarch64` ile çalıştırılabilir. COPR gönderimi ancak tüm RPM/QML kontrollerinden sonra yapılır. Dal push'u tek başına COPR göndermez.
- O kaynak commit'i için RPM kontrolleri ve COPR hedef mimari derlemeleri bitmeli. ISO'nun beklediği commit ile RPM Provides commit'i eşleşmezse imaj işi durur.
- Sen hazır olduğunu söylediğinde ilk VM denemesi için **Actions → ISO → Run workflow** ile geliştirme ISO'su üretilebilir; mimari bu Mac için `aarch64`, Fedora alanı boş bırakılırsa dosyadaki `45` kullanılır. Bu adım şu anda başlatılmaz.
- İlk deneme için `v*` etiketi veya resmi sürüm yayını oluşturulmaz. `RELEASE_VALIDATION_JSON` henüz doldurulmaz; gerçek VM/donanım testlerinden sonra sürüm yayını içindir. Deneme ISO'sunu başlatan manuel akış bu test kaydını istemez; anahtar özeti yine gereklidir.
- Depo public olduğu için özel depo attestation ayarı bu durumda gerekmez. Kaynak doğrulaması ve paket imzası, VM önyükleme veya Secure Boot doğrulamasının yerine geçmez.

GitHub adımlarının dayanağı: [repository variables](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-variables#creating-configuration-variables-for-a-repository). Güven akışı: [ISO_TRUST.md](ISO_TRUST.md). Motor ve VM planı: [RECOVERY_ENGINE.md](RECOVERY_ENGINE.md), [VM_VALIDATION.md](VM_VALIDATION.md).
