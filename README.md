# do_my_qPCRcalc

Web tool that computes relative gene expression from qPCR Cq values (Pfaffl or Livak
method) and returns the results as an Excel file. The user uploads a `.tsv`, `.xlsx` or
`.ods` file (see `template.tsv` and the `example*` files), or pastes the data in the page.

How it works: `index.php` saves the input in `upload/`, runs `qPCR_2_graph_2.pl`, which
writes the result in `download/`, then sends it to the browser. `count_upload/` gets one
empty file per computation (usage counter).

## Requirements

- Apache with PHP (mod_php)
- Perl with `Excel::Writer::XLSX`, `Spreadsheet::ParseExcel` and `Statistics::TTest`
- `ssconvert` (from Gnumeric), to read `.xlsx` and `.ods` files

On Debian / Ubuntu:

```bash
sudo apt install apache2 libapache2-mod-php git perl \
     libexcel-writer-xlsx-perl libspreadsheet-parseexcel-perl libstatistics-ttest-perl
sudo apt install --no-install-recommends gnumeric
sudo a2enmod rewrite headers

# Check: must print OK
perl -MExcel::Writer::XLSX -MSpreadsheet::ParseExcel::Utility -MStatistics::TTest -e 'print "OK\n"'
```

If a Perl module is not packaged: `sudo cpan Statistics::TTest` (or the missing module).

## Installation

Replace `SITE` with the install path and `me` with your Linux user.
Apache is assumed to run as `www-data`.

```bash
SITE=/var/www/html/do_my_qPCRcalc
sudo install -d -o me -g www-data "$SITE"
git clone https://github.com/JeremyTournayre/do_my_qPCRcalc.git "$SITE"
cd "$SITE"
mkdir -p count_upload && cp upload/.htaccess count_upload/
```

### Permissions

The web server must be able to **read** the code and **write** only in `upload/`,
`download/` and `count_upload/`. The `.htaccess` files in these folders must not be
writable by the web server.

```bash
sudo chown -R me:www-data "$SITE"
sudo find "$SITE" -type d -exec chmod 750 {} +
sudo find "$SITE" -type f -exec chmod 640 {} +
for d in upload download count_upload; do
    sudo chown -R www-data:www-data "$SITE/$d"
    sudo chown root:www-data "$SITE/$d/.htaccess"
    sudo chmod 644 "$SITE/$d/.htaccess"
done
```

Update the site with `git pull` as your own user, never with `sudo`.

### Apache

The `.htaccess` files block access to `upload/`, `download/`, `count_upload/`, `.git` and
the Perl script. They only work with `AllowOverride All` on the site folder. For extra
safety, block the data folders in the virtual host too, so they stay closed even if a
`.htaccess` file is deleted:

```apache
<Directory /var/www/html/do_my_qPCRcalc>
    Options -Indexes -ExecCGI
    AllowOverride All
    Require all granted
</Directory>

<DirectoryMatch "^/var/www/html/do_my_qPCRcalc/(upload|download|count_upload|\.git)(/|$)">
    Require all denied
    AllowOverride None
    Options None
    <IfModule mod_php.c>
        php_admin_flag engine off
    </IfModule>
</DirectoryMatch>
```

The root `.htaccess` redirects to `https://qpcr-calcul.clermont.inrae.fr`: change the
domain name in it if you host the tool elsewhere.

Recommended `php.ini` settings (`exec` must stay enabled, `index.php` uses it to run the
Perl script):

```
expose_php = Off
display_errors = Off
disable_functions = system,passthru,shell_exec,proc_open,popen,pcntl_exec
```

### Check

- Upload `example.tsv`, `example.xlsx` and `example.ods` with both methods: an Excel file
  must be downloaded.
- `upload/`, `download/`, `count_upload/`, `.git/config` and `qPCR_2_graph_2.pl` must
  return 403 or 404 in a browser.
