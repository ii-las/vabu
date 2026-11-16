# ISO paket ve yayın doğrulaması

Elle başlatılan geliştirme ISO derlemesi ile `v*` etiketli resmi sürüm yayını ayrı kapılardan geçer. Aşağıdaki doğrulamalar kaynakta uygulanmıştır.

## Paket imzaları

Kiwi tanımında `rpm-check-signatures=true` kullanılır. Fedora ve RPM Fusion açık anahtarları derleme konteynerindeki `distribution-gpg-keys` paketinden alınır. Vabu COPR anahtarı yalnızca yapılandırılmış tam dosya SHA-256 özetiyle eşleşirse kabul edilir. Eksik, hatalı veya değişmiş özet derlemeyi durdurur. Anahtar hiçbir zaman indirildiği yerden elde edilen özetle kendiliğinden güvenilir sayılmaz.

İlk anahtarı kabul etmek operatörün güven kararıdır. Varsa daha önce güvenilir biçimde kaydedilmiş bağımsız parmak iziyle karşılaştırılır. Böyle bir kayıt yoksa doğru proje adresi ve resmi COPR HTTPS hizmeti başlangıç güvenidir; bağımsız anahtar doğrulaması yapıldığı iddia edilmez. Sabitleme sonraki anahtar değişimlerini yakalar; başlangıçta yanlış kabul edilmiş anahtarı kendiliğinden düzeltemez. Dosyanın SHA-256 değeri GitHub repository Variable veya Secret `COPR_KEY_SHA256` olarak verilir; ikisi varsa Variable önceliklidir. Bu değer özel anahtar değildir. Kullanıcı Secret değerini yapılandırdı; agent yalnızca adını okudu ve özeti uydurmadı.

Yerel derlemede aynı değer ortam değişkeni olarak verilir. `tools/prepare-iso-keys.py`, yalnızca böyle bir derleme açıkça başlatıldığında anahtarı alır. Bu araç mevcut Mac üzerinde ağdan anahtar almak için çalıştırılmamıştır. Üretilen `iso/keys/` dosyaları Git'e alınmaz.

## İmzalı yayın kaydı

GitHub ISO akışında `actions/attest@v4`, ISO'nun içeriğini ve derleme kimliğini Sigstore imzalı bir kaynak doğrulama belgesine bağlar. Belge üretilmeden `v*` sürüm yayını yapılmaz. Bu, UEFI Secure Boot imzasının veya donanım/kurulum testinin yerine geçmez.

Public repolarda desteklenen GitHub planlarında çalışır. Private repo için desteklenen Enterprise Cloud planı doğrulanırsa `PRIVATE_ATTESTATIONS_ENABLED=true` değişkeni ayarlanabilir. Destek yoksa imzalı yayın aşaması kapalı kalır; sahte başarı gösterilmez.

Gelecekte indirilen bir ISO, GitHub CLI kurulu bir sistemde `gh attestation verify DOSYA.iso --repo ii-las/vabu` ile doğrulanabilir. İndirme doğrulaması resmi sürüm yayını başlatmaz ve gerçek VM testlerinin yerini tutmaz.

Dayanaklar: [Kiwi imza anahtarı şeması](https://osinside.github.io/kiwi/image_description/elements.html), [GitHub imzalı kaynak doğrulama eylemi](https://github.com/actions/attest).

## Gerçek test kaydı

`v*` etiketli sürüm işleri imza şartından önce ayrıca kaynak commit, mimari ve Fedora ile eşleşen `RELEASE_VALIDATION_JSON` kaydını ister. Gerçek testler yapılmadığı için bu değer ayarlanmadı; sürüm yayını kapalı kalır. Kapsam ve kayıt biçimi: [RECOVERY.md](RECOVERY.md).

Kullanıcının nereden ne alacağı ve hangi GitHub alanına yazacağı: [ISO_SETUP.md](ISO_SETUP.md). Agent Mac üzerinde gerçek açık anahtar almadı veya GitHub değişkeni ayarlamadı; kullanıcının eklediği Secret akışa bağlandı.
