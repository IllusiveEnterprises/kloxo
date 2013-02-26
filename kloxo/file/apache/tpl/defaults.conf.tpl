### begin content - please not remove this line
<?php
if ($reverseproxy) {
    $ports[] = '30080';
    $ports[] = '30443';
} else {
    $ports[] = '80';
    $ports[] = '443';
}

if ($setdefaults === 'webmail') {
    if ($webmailappdefault) {
        $docroot = "/home/kloxo/httpd/webmail/{$webmailappdefault}";
    } else {
        $docroot = "/home/kloxo/httpd/webmail";
    }
} else {
    $docroot = "/home/kloxo/httpd/{$setdefaults}";
}

if ($indexorder) {
    $indexorder = implode(' ', $indexorder);
}

// MR -- for watchdog monitoring set fpmport for apache to 50000
// $userinfoapache = posix_getpwnam('apache');
// $fpmportapache = (50000 + $userinfoapache['uid']);
$fpmportapache = 50000;

?>

<?php
if ($setdefaults === 'ssl') {
/*
    foreach ($certnamelist as $ip => $certname) {
?>

<Virtualhost <?php echo $ip; ?>:<?php echo $ports[1]; ?>>

    SSLEngine On
    SSLCertificateFile /home/kloxo/httpd/ssl/<?php echo $certname; ?>.crt
    SSLCertificateKeyFile /home/kloxo/httpd/ssl/<?php echo $certname; ?>.key
    SSLCACertificatefile /home/kloxo/httpd/ssl/<?php echo $certname; ?>.ca

</Virtualhost>

<?php
    }
*/
?>

### No needed declare here because certfile directly write to defaults and domains configs

<?php
} else {
    if ($setdefaults === 'init') {
        foreach ($certnamelist as $ip => $certname) {
?>

Listen <?php echo $ip; ?>:<?php echo $ports[0]; ?>

Listen <?php echo $ip; ?>:<?php echo $ports[1]; ?>


<IfVersion < 2.4>
    NameVirtualHost <?php echo $ip; ?>:<?php echo $ports[0]; ?>

    NameVirtualHost <?php echo $ip; ?>:<?php echo $ports[1]; ?>

</IfVersion>

<?php
        }
    } else {
        foreach ($certnamelist as $ip => $certname) {
            $count = 0;

            foreach ($ports as &$port) {
?>

### '<?php echo $setdefaults; ?>' config
<VirtualHost <?php echo $ip; ?>:<?php echo $port; ?>>

    ServerName <?php echo $setdefaults; ?> 
    ServerAlias <?php echo $setdefaults; ?>.*

    DocumentRoot "<?php echo $docroot; ?>/"

    DirectoryIndex <?php echo $indexorder; ?>

<?php
                if ($count !== 0) {
?>

    <IfModule mod_ssl.c>
        SSLEngine On
        SSLCertificateFile /home/kloxo/httpd/ssl/<?php echo $certname; ?>.crt
        SSLCertificateKeyFile /home/kloxo/httpd/ssl/<?php echo $certname; ?>.key
        SSLCACertificatefile /home/kloxo/httpd/ssl/<?php echo $certname; ?>.ca
    </IfModule>
<?php
                }

            if ($setdefaults === 'default') {
?>

    <Ifmodule mod_userdir.c>
        UserDir enabled
        UserDir "public_html"
<?php
            foreach ($userlist as &$user) {
                $userinfo = posix_getpwnam($user);

                if (!$userinfo) { continue; }
?>
        <Location "/~<?php echo $user; ?>">
            <IfModule mod_suphp.c>
                SuPhp_UserGroup <?php echo $user; ?> <?php echo $user; ?>

            </IfModule>
        </Location>
<?php
                }
?>
    </Ifmodule>
<?php
            }
?>

    <IfModule suexec.c>
        SuexecUserGroup apache apache
    </IfModule>

    <IfModule mod_suphp.c>
        SuPhp_UserGroup apache apache
    </IfModule>

    <IfModule mod_ruid2.c>
        RMode config
        RUidGid apache apache
        RMinUidGid apache apache
    </IfModule>

    <IfModule itk.c>
        AssignUserId apache apache
    </IfModule>

    <IfModule mod_fastcgi.c>
        Alias /<?php echo $setdefaults; ?>.<?php echo $count; ?>fake "<?php echo $docroot; ?>/<?php echo $setdefaults; ?>.<?php echo $count; ?>fake"
        FastCGIExternalServer "<?php echo $docroot; ?>/<?php echo $setdefaults; ?>.<?php echo $count; ?>fake" -host 127.0.0.1:<?php echo $fpmportapache; ?> -idle-timeout 120
        AddType application/x-httpd-fastphp .php
        Action application/x-httpd-fastphp /<?php echo $setdefaults; ?>.<?php echo $count; ?>fake

        <Files "<?php echo $setdefaults; ?>.<?php echo $count; ?>fake">
            RewriteCond %{REQUEST_URI} !<?php echo $setdefaults; ?>.<?php echo $count; ?>fake
        </Files>
    </IfModule>

    <IfModule mod_fcgid.c>
        <Directory "<?php echo $docroot; ?>/">
            Options +ExecCGI
            AllowOverride All
            AddHandler fcgid-script .php
            FCGIWrapper /home/httpd/php5.fcgi .php
            <IfVersion < 2.4>
                Order allow,deny
                Allow from all
            </IfVersion>
            <IfVersion >= 2.4>
                Require all granted
            </IfVersion>
        </Directory>
    </IfModule>

    <IfModule mod_proxy_fcgi.c>
        ProxyPass / fcgi://127.0.0.1:<?php echo $fpmportapache; ?>/ timeout=120
        ProxyPassReverse / fcgi://127.0.0.1:<?php echo $fpmportapache; ?>/ timeout=120
    </IfModule>

    <Location />
        allow from all
        Options +Indexes +FollowSymlinks
    </Location>

</VirtualHost>

<?php
            $count++;
            }
        }
    }
}
?>

### end content - please not remove this line
