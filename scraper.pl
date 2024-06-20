use strict;
use warnings;
use utf8;
use open ':std', ':encoding(utf8)';
use LWP::UserAgent;
use HTML::TreeBuilder;
use DBI;
use POSIX qw(locale_h);

# UTF-8 karakter desteği için locale tanımı
setlocale(LC_ALL, "tr_TR.UTF-8");

# Veritabanı bağlantısı
my $dbh = DBI->connect("dbi:SQLite:dbname=scraper.db", "", "", { RaiseError => 1, PrintError => 0 }) 
    or die "Veritabanı bağlantısı başarısız: $DBI::errstr";

# Kullanıcı aracısı oluşturma
my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;

# Hedef URL
my $url = 'https://sabah.com.tr';  # Buraya hedef siteyi ekleyin

# HTTP isteği gönderme
my $response = $ua->get($url);

if ($response->is_success) {
    my $content = $response->decoded_content;

    # HTML içerik parse edilmesi
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);

    # Haber başlıklarını ve içeriklerini çekme (örnek bir yapı)
    foreach my $article ($tree->look_down(_tag => 'article')) {
        my $title = $article->look_down(_tag => 'h2')->as_text;
        my $author = $article->look_down(_tag => 'span', class => 'author')->as_text;
        my $date = $article->look_down(_tag => 'time')->attr('datetime');
        my $content = $article->look_down(_tag => 'p')->as_text;

        # Veritabanına kaydetme
        my $stmt = "INSERT INTO Articles (title, author, date, content) VALUES (?, ?, ?, ?)";
        my $sth = $dbh->prepare($stmt);
        $sth->execute($title, $author, $date, $content);
    }

    $tree->delete;
} else {
    die "HTTP isteği başarısız: " . $response->status_line;
}

# Veritabanı bağlantısını kapat
$dbh->disconnect();
